
import time
import firebase_admin
from firebase_admin import credentials, firestore
from google.api_core.exceptions import GoogleAPICallError

# Firebase initialization
if not firebase_admin._apps:
    firebase_admin.initialize_app(
        credentials.Certificate("serviceAccountKey.json")
    )

db = firestore.client()
students = db.collection("students")

updated = 0
already_ok = 0
failed = 0
last_doc = None

print("Starting attendance update...\n")

while True:
    # Read a small page instead of streaming all records at once.
    query = students.order_by("__name__").limit(50)

    if last_doc is not None:
        query = query.start_after(last_doc)

    try:
        docs = list(query.stream(timeout=60))

    except Exception as error:
        print("Firestore read error:", error)
        print("Retrying in 5 seconds...")
        time.sleep(5)

        try:
            docs = list(query.stream(timeout=60))
        except Exception as retry_error:
            print("Retry failed:", retry_error)
            print("Stopped safely. Run the script again later.")
            break

    if not docs:
        break

    for doc in docs:
        data = doc.to_dict() or {}

        try:
            current = float(data.get("Attendance", 0) or 0)
        except (TypeError, ValueError):
            current = 0

        if current >= 50:
            already_ok += 1
            continue

        # Demo attendance: deterministic value from 50 to 100.
        seed = sum(ord(char) for char in doc.id)
        new_attendance = 50 + (seed % 51)

        try:
            doc.reference.update({
                "Attendance": float(new_attendance)
            })

            print(f"UPDATED: {doc.id} -> {new_attendance}%")
            updated += 1

        except GoogleAPICallError as error:
            print(f"UPDATE ERROR: {doc.id}: {error}")
            failed += 1

        except Exception as error:
            print(f"ERROR: {doc.id}: {error}")
            failed += 1

    last_doc = docs[-1]
    time.sleep(0.2)

print("\n========== ATTENDANCE SUMMARY ==========")
print("Updated:", updated)
print("Already 50% or above:", already_ok)
print("Failed updates:", failed)
print("========================================")
print("Check errors before assuming all records are updated.")
print("Generated attendance is demo data.")
