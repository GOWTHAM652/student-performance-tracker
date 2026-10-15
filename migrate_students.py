
import json
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore, auth

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        credentials.Certificate("serviceAccountKey.json")
    )

db = firestore.client()

# Even distribution: 50 students across six departments.
DEPARTMENTS = [
    ("CS", "CSE", "Computer Science and Engineering", "cs"),
    ("AD", "AIDS", "Artificial Intelligence and Data Science", "ad"),
    ("AL", "AIML", "Artificial Intelligence and Machine Learning", "al"),
    ("EE", "EEE", "Electrical and Electronics Engineering", "ee"),
    ("EC", "ECE", "Electronics and Communication Engineering", "ec"),
    ("IT", "IT", "Information Technology", "it"),
]

BATCH = "2024-2028"
BATCH_CODE = "24"
MAX_SEMESTER = 5

# Load all existing demo records before changing anything.
records = []
for number in range(105, 155):
    old_id = f"7376241CS{number}"
    snap = db.collection("students").document(old_id).get()

    if not snap.exists:
        raise RuntimeError(f"Missing Firestore record: {old_id}")

    data = snap.to_dict() or {}
    old_email = data.get("Email")

    if not old_email:
        raise RuntimeError(f"Missing email in {old_id}")

    records.append({
        "number": number,
        "old_id": old_id,
        "old_email": old_email,
        "data": data,
    })

# Write a complete backup before any migration.
backup_file = (
    "students_backup_"
    + datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    + ".json"
)

with open(backup_file, "w", encoding="utf-8") as f:
    json.dump(records, f, indent=2, ensure_ascii=False, default=str)

print(f"Backup saved: {backup_file}")
print("Preview of planned changes:")

plans = []
for item in records:
    number = item["number"]
    prefix, code, name, suffix = DEPARTMENTS[
        (number - 105) % len(DEPARTMENTS)
    ]

    new_id = f"7376241{prefix}{number}"
    new_email = f"student{number}.{suffix}{BATCH_CODE}@bitsathy.ac.in"

    plans.append({
        **item,
        "new_id": new_id,
        "new_email": new_email,
        "prefix": prefix,
        "code": code,
        "department": name,
    })

    print(
        f"{item['old_id']} -> {new_id} | "
        f"{item['old_email']} -> {new_email}"
    )

# Stop if a target document already exists unexpectedly.
for p in plans:
    if p["new_id"] != p["old_id"]:
        if db.collection("students").document(p["new_id"]).get().exists:
            raise RuntimeError(
                f"Target document already exists: {p['new_id']}. "
                "No migration performed."
            )

# Check that target emails aren't used by unrelated Auth accounts.
for p in plans:
    try:
        auth.get_user_by_email(p["new_email"])
        if p["new_email"] != p["old_email"]:
            raise RuntimeError(
                f"Target Auth email already exists: {p['new_email']}. "
                "No migration performed."
            )
    except auth.UserNotFoundError:
        pass

# Confirm before making live changes.
confirm = input(
    "\nThis will change Firestore IDs and Firebase Auth emails. "
    "Passwords remain unchanged. Type MIGRATE to continue: "
).strip()

if confirm != "MIGRATE":
    print("Cancelled. No records were migrated.")
    raise SystemExit(0)

# Migrate each record. Keep the old Firestore document until
# the new document and Auth email have been updated successfully.
for p in plans:
    number = p["number"]
    old_ref = db.collection("students").document(p["old_id"])
    new_ref = db.collection("students").document(p["new_id"])

    try:
        user = auth.get_user_by_email(p["old_email"])

        updated = dict(p["data"])
        updated.update({
            "RegisterNumber": p["new_id"],
            "Email": p["new_email"],
            "Batch": BATCH,
            "DepartmentCode": p["prefix"],
            "Department": p["department"],
            "Semester": min(
                MAX_SEMESTER,
                max(1, int(updated.get("Semester", 1)))
            ),
        })

        # Write destination document first.
        new_ref.set(updated)

        # Update Firebase Auth email; password is not changed.
        if p["new_email"] != p["old_email"]:
            auth.update_user(user.uid, email=p["new_email"])

        # Remove old document only after prior steps succeed.
        if p["new_id"] != p["old_id"]:
            old_ref.delete()

        print(f"MIGRATED: {p['new_id']} | {p['new_email']}")

    except Exception as e:
        print(
            f"ERROR for {p['old_id']}: {e}\n"
            "Old document was retained unless deletion had already occurred. "
            "Check Auth and Firestore before retrying."
        )
        break

print("\nMigration finished or stopped. Review every MIGRATED/ERROR line.")
print("Keep the backup file and serviceAccountKey.json private.")
