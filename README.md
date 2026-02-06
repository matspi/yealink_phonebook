# Phonebook

A lightweight web application for maintaining a phonebook with support for Yealink IP phones.

## Features

- 📝 Simple web interface for managing contacts
- 📞 Support for up to 3 phone numbers per contact
- 📱 XML export for Yealink IP phones
- 🐳 Docker support for easy deployment
- 🔄 RESTful API
- 💾 SQLite database (no external database required)

## Tech Stack

**Backend:**
- Python 3.11+
- FastAPI - Modern, fast web framework
- SQLAlchemy - SQL toolkit and ORM
- SQLite - Lightweight database
- Uvicorn - ASGI server

**Frontend:**
- HTML5
- CSS3
- Vanilla JavaScript (no framework required)

## Quick Start

### Using Docker (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/yourusername/spiller_phonebook.git
cd spiller_phonebook
```

2. Start the application:
```bash
docker-compose up -d
```

3. Access the application:
- Web Interface: http://localhost:8000/frontend/
- API Documentation: http://localhost:8000/docs
- Yealink XML: http://localhost:8000/yealink/phonebook.xml

### Manual Setup

1. **Install Python dependencies:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. **Start the backend:**
```bash
python main.py
```

3. **Access the frontend:**
Open `frontend/index.html` in your browser, or serve it with a simple HTTP server:
```bash
cd frontend
python -m http.server 8080
```

Then access http://localhost:8080

## API Endpoints

### Contacts

- `GET /api/contacts` - List all contacts
- `GET /api/contacts/{id}` - Get a specific contact
- `POST /api/contacts` - Create a new contact
- `PUT /api/contacts/{id}` - Update a contact
- `DELETE /api/contacts/{id}` - Delete a contact

### Yealink Integration

- `GET /yealink/phonebook.xml` - XML phonebook for Yealink IP phones

## Yealink IP Phone Setup

1. Access your Yealink phone's web interface
2. Navigate to Directory → Remote Phone Book
3. Set the Remote URL to: `http://your-server:8000/yealink/phonebook.xml`
4. Save and the phonebook will sync automatically

## Development

### Project Structure

```
spiller_phonebook/
├── backend/
│   ├── main.py           # FastAPI application
│   ├── models.py         # SQLAlchemy models
│   ├── schemas.py        # Pydantic schemas
│   ├── database.py       # Database configuration
│   └── requirements.txt  # Python dependencies
├── frontend/
│   ├── index.html        # Main HTML page
│   ├── style.css         # Styles
│   └── app.js           # JavaScript application
├── .github/
│   └── workflows/       # CI/CD workflows
├── Dockerfile
├── docker-compose.yml
└── README.md
```

### Running Tests

```bash
cd backend
pip install pytest pytest-cov httpx
pytest
```

### Database

The SQLite database is created automatically on first run. By default, it's stored as `phonebook.db` in the backend directory.

To use a different location, set the `DATABASE_URL` environment variable:
```bash
export DATABASE_URL=sqlite:////path/to/your/database.db
```

## Deployment to Proxmox LXC

### Option 1: Docker in LXC

1. Create a new LXC container (Ubuntu 22.04 recommended)
2. Make it privileged or enable nesting: `Features → Nesting`
3. Install Docker in the container:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

4. Clone and run the application:
```bash
git clone https://github.com/yourusername/spiller_phonebook.git
cd spiller_phonebook
docker-compose up -d
```

### Option 2: Direct Installation

1. Create a new LXC container (Ubuntu 22.04)
2. Install Python:
```bash
apt update
apt install python3.11 python3-pip -y
```

3. Clone and setup:
```bash
git clone https://github.com/yourusername/spiller_phonebook.git
cd spiller_phonebook/backend
pip install -r requirements.txt
```

4. Create a systemd service (`/etc/systemd/system/phonebook.service`):
```ini
[Unit]
Description=Phonebook API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/spiller_phonebook/backend
Environment="DATABASE_URL=sqlite:////var/lib/phonebook/phonebook.db"
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

5. Enable and start:
```bash
systemctl enable phonebook
systemctl start phonebook
```

## Environment Variables

- `DATABASE_URL` - Database connection string (default: `sqlite:///./phonebook.db`)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - feel free to use this project for any purpose.

## Support

For issues and questions, please use the GitHub issue tracker.
