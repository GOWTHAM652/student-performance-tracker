
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate(
    "student-performance-trac-561e1-firebase-adminsdk-fbsvc-d2ce364166.json"
)

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Subject marks for each student
subjects = {
    "Agile Software Development": 82,
    "Computer Networks": 78,
    "Free Open Source Software": 90,
    "Machine Learning Essentials": 68,
    "Theory of Computation": 85
}

students = [
    {
        "Name": "Priya Kumar",
        "RegisterNumber": "7376241CS102",
        "Email": "priya.cs24@bitsathy.ac.in",
        "Department": "Computer Science",
        "Batch": "2024-2028",
        "Semester": 5,
        "Attendance": 88,
        "SGPA": 8.5,
        "CGPA": 8.2,
        "Subject Marks": subjects.copy()
    },
    {
        "Name": "Karthik Raj",
        "RegisterNumber": "7376241CS103",
        "Email": "karthik.cs24@bitsathy.ac.in",
        "Department": "Computer Science",
        "Batch": "2024-2028",
        "Semester": 5,
        "Attendance": 72,
        "SGPA": 6.4,
        "CGPA": 6.8,
        "Subject Marks": {
            "Agile Software Development": 65,
            "Computer Networks": 70,
            "Free Open Source Software": 75,
            "Machine Learning Essentials": 60,
            "Theory of Computation": 68
        }
    },
    {
        "Name": "Divya Sri",
        "RegisterNumber": "7376241CS104",
        "Email": "divya.cs24@bitsathy.ac.in",
        "Department": "Computer Science",
        "Batch": "2024-2028",
        "Semester": 5,
        "Attendance": 95,
        "SGPA": 9.1,
        "CGPA": 8.9,
        "Subject Marks": {
            "Agile Software Development": 95,
            "Computer Networks": 92,
            "Free Open Source Software": 96,
            "Machine Learning Essentials": 90,
            "Theory of Computation": 94
        }
    }
]

# Upload or update student documents
for student in students:
    reg_no = student["RegisterNumber"]

    db.collection("students").document(reg_no).set(student)

    print("Uploaded:", student["Name"], "-", reg_no)

print("All student records uploaded successfully!")
