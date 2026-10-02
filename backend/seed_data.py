from app.database import Base, SessionLocal, engine
from app.models.complaint import Complaint
from app.models.location import Location
from app.models.staff import Staff
from app.models.user import User
from app.services.auth_service import get_password_hash

Base.metadata.create_all(bind=engine)

db = SessionLocal()

# Allow repeated runs without failing on duplicate demo data.
db.query(Complaint).delete()
db.query(Location).delete()

if not db.query(User).filter(User.email == "student@campuscare.com").first():
    student = User(
        name="Rahul Sharma",
        email="student@campuscare.com",
        password_hash=get_password_hash("student123"),
        role="student",
        phone="9876543210",
        department="CSE",
        student_id="CS-2024-101",
        year="2nd Year",
    )
    db.add(student)
    db.commit()
    db.refresh(student)
else:
    student = db.query(User).filter(User.email == "student@campuscare.com").first()

if not db.query(User).filter(User.email == "admin@campuscare.com").first():
    admin = User(
        name="Admin User",
        email="admin@campuscare.com",
        password_hash=get_password_hash("admin123"),
        role="admin",
        phone="9988776655",
        department="Administration",
        employee_id="ADM-001",
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
else:
    admin = db.query(User).filter(User.email == "admin@campuscare.com").first()

if not db.query(User).filter(User.email == "staff@campuscare.com").first():
    staff_user = User(
        name="Maintenance Staff",
        email="staff@campuscare.com",
        password_hash=get_password_hash("staff123"),
        role="staff",
        phone="9911223344",
        department="Electrical",
        employee_id="STF-101",
    )
    db.add(staff_user)
    db.commit()
    db.refresh(staff_user)
else:
    staff_user = db.query(User).filter(User.email == "staff@campuscare.com").first()

if not db.query(Staff).filter(Staff.user_id == staff_user.id).first():
    staff_profile = Staff(user_id=staff_user.id, department="Electrical", specialization="Electrical", active=True)
    db.add(staff_profile)
    db.commit()
    db.refresh(staff_profile)
else:
    staff_profile = db.query(Staff).filter(Staff.user_id == staff_user.id).first()

locations = [
    Location(location_code="CSE_LAB_01", location_name="CSE Lab 1", building="Main Building", floor="2nd Floor", qr_code="CSE_LAB_01"),
    Location(location_code="CSE_LAB_02", location_name="CSE Lab 2", building="Main Building", floor="2nd Floor", qr_code="CSE_LAB_02"),
    Location(location_code="CL_101", location_name="Classroom 101", building="Main Building", floor="1st Floor", qr_code="CL_101"),
    Location(location_code="LIBRARY", location_name="Library", building="Academic Block", floor="Ground Floor", qr_code="LIBRARY"),
    Location(location_code="MAIN_BUILDING", location_name="Main Building", building="Main Building", floor="Ground Floor", qr_code="MAIN_BUILDING"),
]

for location in locations:
    if not db.query(Location).filter(Location.location_code == location.location_code).first():
        db.add(location)

db.commit()

sample_complaints = [
    ("Electrical", "Both tube lights in CSE Lab 2 are not working.", "CSE_LAB_02", "Medium", "Electrical", "Medium"),
    ("Plumbing", "There is water leaking from the pipe near the main building corridor.", "MAIN_BUILDING", "High", "Plumbing", "High"),
    ("Wi-Fi", "Internet connection is not working in the library for students.", "LIBRARY", "High", "Wi-Fi", "High"),
    ("Classroom", "One of the classroom chairs is broken in Room 101.", "CL_101", "Low", "Classroom", "Low"),
]

next_number = 1001
existing_numbers = {item.complaint_number for item in db.query(Complaint.complaint_number).all()}
for category, desc, loc_code, priority, ai_category, ai_priority in sample_complaints:
    existing = db.query(Complaint).filter(Complaint.description == desc).first()
    if existing:
        continue

    while f"CC{next_number}" in existing_numbers:
        next_number += 1

    location = db.query(Location).filter(Location.location_code == loc_code).first()
    complaint = Complaint(
        complaint_number=f"CC{next_number}",
        student_id=student.id,
        category=category,
        description=desc,
        location_id=location.id if location else None,
        priority=priority,
        ai_category=ai_category,
        ai_priority=ai_priority,
        ai_confidence="0.91",
        status="Reported",
    )
    db.add(complaint)
    existing_numbers.add(complaint.complaint_number)
    next_number += 1

db.commit()
print("Demo data seeded successfully.")
