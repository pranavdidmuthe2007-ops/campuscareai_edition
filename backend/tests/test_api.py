from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    payload = response.json()
    assert payload["app"] == "CampusCare AI"
    assert payload["message"] == "CampusCare AI API is running"


def test_login_success_for_student():
    response = client.post(
        "/auth/login",
        json={"email": "student@campuscare.com", "password": "student123"},
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["token_type"] == "bearer"
    assert "access_token" in payload
    assert payload["access_token"]


def test_me_endpoint_returns_current_user():
    login = client.post(
        "/auth/login",
        json={"email": "student@campuscare.com", "password": "student123"},
    )
    token = login.json()["access_token"]

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["email"] == "student@campuscare.com"
    assert payload["role"] == "student"


def test_student_complaints_list_returns_seeded_data():
    login = client.post(
        "/auth/login",
        json={"email": "student@campuscare.com", "password": "student123"},
    )
    token = login.json()["access_token"]

    response = client.get(
        "/complaints",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    complaints = response.json()
    assert isinstance(complaints, list)
    assert len(complaints) >= 1
    assert complaints[0]["student_id"] == 1
    assert "complaint_number" in complaints[0]
