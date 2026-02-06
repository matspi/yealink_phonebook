"""
Pydantic schemas for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional


class ContactBase(BaseModel):
    """Base contact schema."""
    name: str = Field(..., min_length=1, max_length=255)
    phone1: Optional[str] = Field(None, max_length=50)
    phone2: Optional[str] = Field(None, max_length=50)
    phone3: Optional[str] = Field(None, max_length=50)


class ContactCreate(ContactBase):
    """Schema for creating a contact."""
    pass


class ContactUpdate(ContactBase):
    """Schema for updating a contact (all fields optional)."""
    name: Optional[str] = Field(None, min_length=1, max_length=255)


class ContactResponse(ContactBase):
    """Schema for contact response with ID."""
    id: int

    class Config:
        from_attributes = True
