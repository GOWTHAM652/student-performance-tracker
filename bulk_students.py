
import csv
import secrets
import string
import firebase_admin

from firebase_admin import credentials, auth, firestore

# 1. Firebase service account key
SERVICE_KEY = "serviceAccountKey.json"

cred = credentials.Certificate(SERVICE_KEY)

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 2. Student details
DEPARTMENT = "Computer Science"
BATCH = "2024-2028"
SEMESTER = 5

SUBJECTS = [
    "Agile Software Development",
    "Computer Networks",
    "Free Open Source Software",
    "Machine Learning Essentials",
    "Theory of Computation"
]

# Generate a random temporary password for each new account
def generate_password():
    chars = string.ascii_letters + string.digits + "!@#"
    while True:
        password = ''.join(secrets.choice(chars) for _ in range(12))
        if (any(c.islower() for c in password)
                and any(c.isupper() for c in password)
                and any(c.isdigit() for c in password)
                and any(c in "!@#" for c in password)):
            return password


with open(
    "student_credentials.csv",
    "w",
    newline="",
    encoding="utf-8"
) as file:

    writer = csv.writer(file)
    writer.writerow([
        "Name", "Register Number", "Email",
        "Temporary Password", "Status"
    ])

    for number in range(105, 155):  # 50 students
        reg_no = f"7376241CS{number:03d}"
        email = f"student{number}.cs24@bitsathy.ac.in"
        name = f"Student {number}"

        # Generate marks and academic data
        marks = {
            subject: secrets.randbelow(41) + 60
            for subject in SUBJECTS
        }

        average = sum(marks.values()) / len(marks)
        attendance = secrets.randbelow(31) + 70
        cgpa = round(average / 10, 1)
        sgpa = round(max(0, min(10, cgpa + 0.2)), 1)

        password = ""
        status = ""

        # 3. Create Authentication account
        try:
            password = generate_password()

            auth.create_user(
                email=email,
                password=password,
                display_name=name
            )
            status = "Created"

        except auth.EmailAlreadyExistsError:
            status = "Account already exists; password unchanged"

        except Exception as error:
            print(f"Auth error for {email}: {error}")
            writer.writerow([
                name, reg_no, email, "", "AUTH FAILED"
            ])
            continue

        # 4. Upload the matching Firestore document
        student_data = {
            "Name": name,
            "RegisterNumber": reg_no,
            "Email": email,
            "Department": DEPARTMENT,
            "Batch": BATCH,
            "Semester": SEMESTER,
            "Attendance": attendance,
            "SGPA": sgpa,
            "CGPA": cgpa,
            "Subject Marks": marks
        }

        try:
            db.collection("students").document(reg_no).set(
                student_data
            )

            writer.writerow([
                name, reg_no, email, password, status
            ])

            print(f"Uploaded {number - 104}/50: {name}")

        except Exception as error:
            print(f"Firestore error for {email}: {error}")
            writer.writerow([
                name, reg_no, email, password, "FIRESTORE FAILED"
            ])

print("\nCompleted. Check student_credentials.csv")
print("Review any errors printed above.")
