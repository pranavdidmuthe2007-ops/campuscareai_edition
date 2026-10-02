from sqlalchemy.orm import Session

from app.models.notification import Notification


def create_notification(db: Session, *, user_id: int, title: str, message: str, complaint_id: int | None = None) -> Notification:
    notification = Notification(
        user_id=user_id,
        complaint_id=complaint_id,
        title=title,
        message=message,
        is_read=False,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification
