
import csv
import firebase_admin
from firebase_admin import credentials, auth

cred = credentials.Certificate("serviceAccountKey.json")

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

with open("student_credentials.csv", "w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)
    writer.writerow(["Email", "Password", "Status"])

    for number in range(105, 155):
        email = f"student{number}.cs24@bitsathy.ac.in"
        password = f"Student{number}@2026"

        try:
            user = auth.get_user_by_email(email)
            auth.update_user(user.uid, password=password)

            writer.writerow([email, password, "Updated"])
            print(f"Updated: {email}")

        except Exception as error:
            writer.writerow([email, "", f"FAILED: {error}"])
            print(f"Failed: {email} - {error}")

print("\nCompleted. Check student_credentials.csv")
