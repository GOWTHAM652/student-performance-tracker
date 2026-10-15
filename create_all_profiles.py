
import firebase_admin
from firebase_admin import credentials, firestore, auth

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

BATCHES = [
    ("2023-2027", "23", "7376231", 7),
    ("2024-2028", "24", "7376241", 5),
    ("2025-2029", "25", "7376251", 3),
]

SUBJECTS = {
    "CSE": ["Programming", "Data Structures", "OOP", "Database Systems"],
    "AIDS": ["Programming", "Statistics", "Data Analytics", "Machine Learning"],
    "AIML": ["Programming", "Linear Algebra", "Machine Learning", "Deep Learning"],
    "EEE": ["Mathematics", "Electric Circuits", "Power Systems", "Control Systems"],
    "ECE": ["Mathematics", "Circuit Analysis", "Digital Electronics", "Communication Systems"],
    "IT": ["Programming", "Data Structures", "Web Technology", "Cloud Computing"],
}

def make_marks(student_no, batch_year, dept_index, semester, department):
    marks = {}
    for i, subject in enumerate(SUBJECTS[department]):
        # Different deterministic demo marks for each profile/semester
        marks[subject] = 50 + (
            student_no * 7 + int(batch_year) * 3
            + dept_index * 11 + semester * 5 + i * 9
        ) % 51
    return marks

created = 0
skipped = 0
errors = 0

for student_no in range(101, 153):
    for dept_index, (prefix, code, dept_name, suffix) in enumerate(DEPARTMENTS):
        for batch, year, reg_prefix, max_sem in BATCHES:
            reg_no = f"{reg_prefix}{prefix}{student_no}"
            email = f"student{student_no}.{suffix}{year}@bitsathy.ac.in"

            doc_ref = db.collection("students").document(reg_no)

            # Never overwrite an existing Firestore document.
            if doc_ref.get().exists:
                print("SKIP existing document:", reg_no)
                skipped += 1
                continue

            # Never overwrite an existing Firebase Auth user.
            try:
                auth.get_user_by_email(email)
                print("SKIP existing Auth account:", email)
                skipped += 1
                continue
            except auth.UserNotFoundError:
                pass

            try:
                # Demo password for newly created accounts only.
                password = f"Student{student_no}@2026"

                user = auth.create_user(
                    email=email,
                    password=password,
                    display_name=f"Student {student_no} - {code} {year}",
                )

                semester_results = {}
                sgpas = []

                for sem in range(1, max_sem + 1):
                    marks = make_marks(
                        student_no, year, dept_index, sem, code
                    )
                    average = sum(marks.values()) / len(marks)
                    sgpa = round(average / 10, 2)
                    sgpas.append(sgpa)

                    semester_results[f"Semester {sem}"] = {
                        "Semester": sem,
                        "Subject Marks": marks,
                        "Average Marks": round(average, 2),
                        "SGPA": sgpa,
                        "Completed": True,
                    }

                latest = semester_results[f"Semester {max_sem}"]

                doc_ref.set({
                    "Name": f"Student {student_no}",
                    "RegisterNumber": reg_no,
                    "Email": email,
                    "DepartmentCode": prefix,
                    "Department": dept_name,
                    "Batch": batch,
                    "Semester": max_sem,
                    "Semester Results": semester_results,
                    "Subject Marks": latest["Subject Marks"],
                    "SGPA": latest["SGPA"],
                    "CGPA": round(sum(sgpas) / len(sgpas), 2),
                    "FirebaseUID": user.uid,
                })

                print("CREATED:", reg_no, email, batch)
                created += 1

            except Exception as e:
                print("ERROR:", reg_no, email, str(e))
                errors += 1

print("\nFinished")
print("Created:", created)
print("Skipped:", skipped)
print("Errors:", errors)
print("Total expected profile combinations:", 936)
print("Generated marks are demo data.")
