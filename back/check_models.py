from app.models.models import Participant, Course, Module, ParticipantCourse
from sqlalchemy import inspect

def check_model_fields():
    """Check what fields each model actually has"""

    models = [Participant, Course, Module, ParticipantCourse]

    for model in models:
        print(f"\n=== {model.__name__} Model Fields ===")
        inspector = inspect(model)
        for column in inspector.columns:
            print(f"  {column.name}: {column.type}")

if __name__ == "__main__":
    check_model_fields()
