
import json
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore, auth

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        credentials.Certificate("serviceAccountKey.json")
    )

db = firestore.client()

# Prefix, department code, department name, email suffix
DEPARTMENTS = [
    ("CS", "CSE", "Computer Science and Engineering", "cs"),
    ("AD", "AIDS", "Artificial Intelligence and Data Science", "ad"),
    ("AL", "AIML", "Artificial Intelligence and Machine Learning", "al"),
    ("EE", "EEE", "Electrical and Electronics Engineering", "ee"),
    ("EC", "ECE", "Electronics and Communication Engineering", "ec"),
    ("IT", "IT", "Information Technology", "it"),
]

# 17 + 17 + 16 students
def get_batch(number):
    if number <= 121:
        return "2023-2027", "23", "7376231", 7
    elif number <= 138:
        return "2024-2028", "24", "7376241", 5
    return "2025-2029", "25", "7376251", 3

# Read existing records using the previous department distribution.
plans = []

for number in range(105, 155):
    prefix, dept_code, dept_name, suffix = DEPARTMENTS[
        (number - 105) % 6
    ]

    old_id = f"7376241{prefix}{number}"
    old_ref = db.collection("students").document(old_id)
    snap = old_ref.get()

    if not snap.exists:
        raise RuntimeError(
            f"Missing record {old_id}. No migration started."
        )

    data = snap.to_dict() or {}
    old_email = data.get("Email")

    if not old_email:
        raise RuntimeError(f"Missing email in {old_id}")

    batch, year, reg_prefix, max_sem = get_batch(number)
    new_id = f"{reg_prefix}{prefix}{number}"
    new_email = f"student{number}.{suffix}{year}@bitsathy.ac.in"

    plans.append({
        "number": number,
        "old_id": old_id,
        "old_email": old_email,
        "data": data,
        "new_id": new_id,
        "new_email": new_email,
        "batch": batch,
        "max_sem": max_sem,
        "dept_code": dept_code,
        "dept_name": dept_name,
    })

# Back up current Firestore data before changes.
backup_name = "batch_backup_" + datetime.now().strftime(
    "%Y%m%d_%H%M%S"
) + ".json"

with open(backup_name, "w", encoding="utf-8") as file:
    json.dump(plans, file, indent=2, ensure_ascii=False, default=str)

print("Backup created:", backup_name)

# Check all destination IDs before making changes.
for p in plans:
    if p["new_id"] != p["old_id"]:
        if db.collection("students").document(p["new_id"]).get().exists:
            raise RuntimeError(
                f"Destination already exists: {p['new_id']}. "
                "No migration started."
            )

# Check target Authentication emails are available.
for p in plans:
    try:
        auth.get_user_by_email(p["new_email"])
        if p["new_email"] != p["old_email"]:
            raise RuntimeError(
                f"Target email already exists: {p['new_email']}. "
                "No migration started."
            )
    except auth.UserNotFoundError:
        pass

print("\nPREVIEW")
for p in plans:
    print(
        p["old_id"], "->", p["new_id"],
        "|", p["batch"], "|", p["new_email"]
    )

confirm = input(
    "\nType MIGRATE to update Firestore and Auth emails: "
).strip()

if confirm != "MIGRATE":
    print("Cancelled. No changes made.")
    raise SystemExit

for p in plans:
    old_ref = db.collection("students").document(p["old_id"])
    new_ref = db.collection("students").document(p["new_id"])
    data = dict(p["data"])

    try:
        # Keep only semester results allowed for the assigned batch.
        results = data.get("Semester Results", {})
        if isinstance(results, dict):
            results = {
                key: value for key, value in results.items()
                if int(value.get("Semester", key.split()[-1]))
                <= p["max_sem"]
            }
            data["Semester Results"] = results

        current_sem = min(
            p["max_sem"],
            max(1, int(data.get("Semester", 1)))
        )
        data["Semester"] = current_sem
        data.update({
            "RegisterNumber": p["new_id"],
            "Email": p["new_email"],
            "Batch": p["batch"],
            "DepartmentCode": p["dept_code"],
            "Department": p["dept_name"],
        })

        if results:
            latest = results.get(f"Semester {current_sem}")
            if latest:
                data["Subject Marks"] = latest.get(
                    "Subject Marks", data.get("Subject Marks", {})
                )
                data["SGPA"] = latest.get("SGPA", data.get("SGPA", 0))

            sgpas = [
                item["SGPA"] for item in results.values()
                if isinstance(item, dict) and "SGPA" in item
            ]
            if sgpas:
                data["CGPA"] = round(sum(sgpas) / len(sgpas), 2)

        # Write new Firestore record first.
        new_ref.set(data)

        # Update Auth email without changing password.
        user = auth.get_user_by_email(p["old_email"])
        if p["new_email"] != p["old_email"]:
            auth.update_user(user.uid, email=p["new_email"])

        # Delete old record only after previous operations succeed.
        if p["new_id"] != p["old_id"]:
            old_ref.delete()

        print("MIGRATED:", p["new_id"], p["batch"], p["new_email"])

    except Exception as error:
        print("ERROR:", p["old_id"], error)
        print("Stop and inspect Firestore/Auth before retrying.")
        break

print("\nMigration run finished. Review all output.")
