"""
SQLAlchemy models for the phonebook database.
"""
from sqlalchemy import Column, Integer, String
from database import Base


class Contact(Base):
    """Contact model with name and up to 3 phone numbers."""

    __tablename__ = "contacts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    phone1 = Column(String, nullable=True)
    phone2 = Column(String, nullable=True)
    phone3 = Column(String, nullable=True)

    def __repr__(self):
        return f"<Contact(name={self.name}, phone1={self.phone1})>"
