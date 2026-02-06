// API Configuration
// Use relative URL to work with any hostname
const API_BASE_URL = '/api';

// DOM Elements
const contactForm = document.getElementById('contactForm');
const contactsBody = document.getElementById('contactsBody');
const contactsTable = document.getElementById('contactsTable');
const loading = document.getElementById('loading');
const error = document.getElementById('error');
const emptyState = document.getElementById('emptyState');
const formTitle = document.getElementById('form-title');
const submitBtn = document.getElementById('submitBtn');
const cancelBtn = document.getElementById('cancelBtn');
const contactIdInput = document.getElementById('contactId');

// State
let editingContactId = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadContacts();
    contactForm.addEventListener('submit', handleSubmit);
    cancelBtn.addEventListener('click', resetForm);
});

// Load all contacts
async function loadContacts() {
    try {
        showLoading();
        const response = await fetch(`${API_BASE_URL}/contacts`);

        if (!response.ok) {
            throw new Error('Kontakte konnten nicht geladen werden');
        }

        const contacts = await response.json();
        displayContacts(contacts);
        hideLoading();
    } catch (err) {
        showError('Fehler beim Laden der Kontakte: ' + err.message);
        hideLoading();
    }
}

// Display contacts in table
function displayContacts(contacts) {
    contactsBody.innerHTML = '';

    if (contacts.length === 0) {
        contactsTable.style.display = 'none';
        emptyState.style.display = 'block';
        return;
    }

    contactsTable.style.display = 'table';
    emptyState.style.display = 'none';

    contacts.forEach(contact => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${escapeHtml(contact.name)}</td>
            <td>${escapeHtml(contact.phone1 || '-')}</td>
            <td>${escapeHtml(contact.phone2 || '-')}</td>
            <td>${escapeHtml(contact.phone3 || '-')}</td>
            <td>
                <button class="btn btn-edit" onclick="editContact(${contact.id})">Bearbeiten</button>
                <button class="btn btn-delete" onclick="deleteContact(${contact.id})">Löschen</button>
            </td>
        `;
        contactsBody.appendChild(row);
    });
}

// Handle form submission
async function handleSubmit(e) {
    e.preventDefault();

    const formData = {
        name: document.getElementById('name').value,
        phone1: document.getElementById('phone1').value || null,
        phone2: document.getElementById('phone2').value || null,
        phone3: document.getElementById('phone3').value || null
    };

    try {
        let response;
        if (editingContactId) {
            // Update existing contact
            response = await fetch(`${API_BASE_URL}/contacts/${editingContactId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
        } else {
            // Create new contact
            response = await fetch(`${API_BASE_URL}/contacts`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
        }

        if (!response.ok) {
            throw new Error('Kontakt konnte nicht gespeichert werden');
        }

        resetForm();
        loadContacts();
    } catch (err) {
        showError('Fehler beim Speichern des Kontakts: ' + err.message);
    }
}

// Edit contact
async function editContact(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/contacts/${id}`);

        if (!response.ok) {
            throw new Error('Kontakt konnte nicht geladen werden');
        }

        const contact = await response.json();

        // Populate form
        document.getElementById('name').value = contact.name;
        document.getElementById('phone1').value = contact.phone1 || '';
        document.getElementById('phone2').value = contact.phone2 || '';
        document.getElementById('phone3').value = contact.phone3 || '';

        // Update UI state
        editingContactId = id;
        formTitle.textContent = 'Kontakt bearbeiten';
        submitBtn.textContent = 'Kontakt aktualisieren';
        cancelBtn.style.display = 'inline-block';

        // Scroll to form
        contactForm.scrollIntoView({ behavior: 'smooth' });
    } catch (err) {
        showError('Fehler beim Laden des Kontakts zum Bearbeiten: ' + err.message);
    }
}

// Delete contact
async function deleteContact(id) {
    if (!confirm('Möchten Sie diesen Kontakt wirklich löschen?')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/contacts/${id}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            throw new Error('Kontakt konnte nicht gelöscht werden');
        }

        loadContacts();
    } catch (err) {
        showError('Fehler beim Löschen des Kontakts: ' + err.message);
    }
}

// Reset form to initial state
function resetForm() {
    contactForm.reset();
    editingContactId = null;
    formTitle.textContent = 'Neuen Kontakt hinzufügen';
    submitBtn.textContent = 'Kontakt hinzufügen';
    cancelBtn.style.display = 'none';
}

// UI helper functions
function showLoading() {
    loading.style.display = 'block';
    error.style.display = 'none';
}

function hideLoading() {
    loading.style.display = 'none';
}

function showError(message) {
    error.textContent = message;
    error.style.display = 'block';
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
