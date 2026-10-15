
import firebase_admin
from firebase_admin import credentials, firestore

# Firebase setup
if not firebase_admin._apps:
    firebase_admin.initialize_app(
        credentials.Certificate("serviceAccountKey.json")
    )

db = firestore.client()

DEPARTMENTS = [
    ("CS", "CSE", "Computer Science and Engineering", "cs"),
    ("AD", "AIDS", "Artificial Intelligence and Data Science", "ad"),
    ("AL", "AIML", "Artificial Intelligence and Machine Learning", "al"),
    ("EE", "EEE", "Electrical and Electronics Engineering", "ee"),
    ("EC", "ECE", "Electronics and Communication Engineering", "ec"),
    ("IT", "IT", "Information Technology", "it"),
]

SUBJECTS = {
    "CSE": [
        "Programming", "Data Structures", "OOP",
        "Database Systems", "Operating Systems",
        "Computer Networks", "Software Engineering",
        "Artificial Intelligence"
    ],
    "AIDS": [
        "Programming", "Statistics", "Data Structures",
        "Database Systems", "Machine Learning",
        "Data Analytics", "Deep Learning", "Data Science"
    ],
    "AIML": [
        "Programming", "Linear Algebra", "Data Structures",
        "Probability and Statistics", "Machine Learning",
        "Neural Networks", "Deep Learning", "AI Project"
    ],
    "EEE": [
        "Engineering Mathematics", "Electric Circuits",
        "Electrical Machines", "Electromagnetic Fields",
        "Power Systems", "Control Systems",
        "Power Electronics", "Renewable Energy"
    ],
    "ECE": [
        "Engineering Mathematics", "Circuit Analysis",
        "Electronic Devices", "Digital Electronics",
        "Signals and Systems", "Communication Systems",
        "Embedded Systems", "Wireless Communication"
    ],
    "IT": [
        "Programming", "Data Structures", "OOP",
        "Database Systems", "Operating Systems",
        "Web Technology", "Cloud Computing",
        "Information Security"
    ],
}

MAX_SEMESTER = {
    "2023-2027": 7,
    "2024-2028": 5,
    "2025-2029": 3,
    "2026-2030": 1,
}

def make_marks(student_number, semester, department):
    subjects = SUBJECTS[department]
    marks = {}

    for index, subject in enumerate(subjects):
        marks[subject] = 60 + (
            student_number * 7 + semester * 5 + index * 3
        ) % 41

    return marks

# IMPORTANT:
# This updates Firestore profile and demo academic data only.
# It does NOT change Firebase Authentication emails/passwords.
# It preserves each existing document ID, Email, and Batch.

for number in range(105, 155):
    reg_no = f"7376241CS{number:03d}"
    ref = db.collection("students").document(reg_no)
    snapshot = ref.get()

    if not snapshot.exists:
        print(f"SKIPPED: {reg_no} not found")
        continue

    data = snapshot.to_dict() or {}
    batch = str(data.get("Batch", "")).strip()

    if batch not in MAX_SEMESTER:
        print(f"SKIPPED: {reg_no} has invalid Batch: {batch}")
        continue

    # Distribute the 50 demo students across 6 departments.
    _, code, department_name, _ = DEPARTMENTS[
        (number - 105) % len(DEPARTMENTS)
    ]

    try:
        current_sem = int(data.get("Semester", 1))
    except (TypeError, ValueError):
        current_sem = 1

    current_sem = max(
        1, min(current_sem, MAX_SEMESTER[batch])
    )

    semester_results = {}

    for sem in range(1, current_sem + 1):
        marks = make_marks(number, sem, code)
        average = sum(marks.values()) / len(marks)
        sgpa = round(average / 10, 2)

        semester_results[f"Semester {sem}"] = {
            "Semester": sem,
            "Subject Marks": marks,
            "Average Marks": round(average, 2),
            "SGPA": sgpa,
            "Completed": True,
        }

    latest = semester_results[f"Semester {current_sem}"]
    cgpa = round(
        sum(item["SGPA"] for item in semester_results.values())
        / len(semester_results),
        2,
    )

    data.update({
        "DepartmentCode": code,
        "Department": department_name,
        "Semester": current_sem,
        "Semester Results": semester_results,
        "Subject Marks": latest["Subject Marks"],
        "SGPA": latest["SGPA"],
        "CGPA": cgpa,
    })

    ref.set(data)

    print(
        f"UPDATED: {reg_no} | {code} | {batch} | "
        f"Semester 1-{current_sem}"
    )

print("\nFinished. Check the output for skipped records.")
print("Generated marks are DEMO data, not official college results.")
