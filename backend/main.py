"""
Main FastAPI application for the phonebook service.
"""
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from typing import List
import uvicorn
import os

from database import get_db, init_db
from models import Contact
from schemas import ContactCreate, ContactResponse, ContactUpdate

app = FastAPI(title="Phonebook API", version="1.0.0")

# CORS middleware for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup."""
    init_db()


@app.get("/api")
async def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "Phonebook API is running"}


@app.get("/api/contacts", response_model=List[ContactResponse])
async def get_contacts(db: Session = Depends(get_db)):
    """Get all contacts."""
    contacts = db.query(Contact).all()
    return contacts


@app.get("/api/contacts/{contact_id}", response_model=ContactResponse)
async def get_contact(contact_id: int, db: Session = Depends(get_db)):
    """Get a specific contact by ID."""
    contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return contact


@app.post("/api/contacts", response_model=ContactResponse, status_code=201)
async def create_contact(contact: ContactCreate, db: Session = Depends(get_db)):
    """Create a new contact."""
    db_contact = Contact(**contact.dict())
    db.add(db_contact)
    db.commit()
    db.refresh(db_contact)
    return db_contact


@app.put("/api/contacts/{contact_id}", response_model=ContactResponse)
async def update_contact(
    contact_id: int, contact: ContactUpdate, db: Session = Depends(get_db)
):
    """Update an existing contact."""
    db_contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    for key, value in contact.dict(exclude_unset=True).items():
        setattr(db_contact, key, value)

    db.commit()
    db.refresh(db_contact)
    return db_contact


@app.delete("/api/contacts/{contact_id}", status_code=204)
async def delete_contact(contact_id: int, db: Session = Depends(get_db)):
    """Delete a contact."""
    db_contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    db.delete(db_contact)
    db.commit()
    return Response(status_code=204)


@app.get("/yealink/phonebook.xml")
async def get_yealink_phonebook(db: Session = Depends(get_db)):
    """
    Generate XML phonebook for Yealink IP phones.
    Format according to: https://support.yealink.com/document-detail/27505959170c49b9a71938534e666998
    """
    contacts = db.query(Contact).all()

    xml_lines = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml_lines.append('<YealinkIPPhoneDirectory>')

    for contact in contacts:
        # Add entries for each phone number
        for phone_num in [contact.phone1, contact.phone2, contact.phone3]:
            if phone_num:
                xml_lines.append('  <DirectoryEntry>')
                xml_lines.append(f'    <Name>{_escape_xml(contact.name)}</Name>')
                xml_lines.append(f'    <Telephone>{_escape_xml(phone_num)}</Telephone>')
                xml_lines.append('  </DirectoryEntry>')

    xml_lines.append('</YealinkIPPhoneDirectory>')

    xml_content = '\n'.join(xml_lines)
    return Response(content=xml_content, media_type="application/xml")


def _escape_xml(text: str) -> str:
    """Escape special XML characters."""
    if not text:
        return ""
    return (text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;"))


# Mount static files for frontend (must be last to not override API routes)
frontend_dir = os.path.join(os.path.dirname(__file__), "..", "frontend")
if os.path.exists(frontend_dir):
    app.mount("/", StaticFiles(directory=frontend_dir, html=True), name="frontend")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
