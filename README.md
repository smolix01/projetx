# Email Delivery Platform

A Production-Grade Email SaaS Platform for managing and sending emails at scale.

## Features

- **SMTP Server**: Built-in Postfix SMTP server for email delivery
- **Email Campaigns**: Create and manage email campaigns with scheduling
- **Email Lists**: Manage contacts with CSV import/export
- **Tracking**: Open and click tracking with detailed analytics
- **Bounce Processing**: Automatic bounce handling and list cleaning
- **API**: RESTful API for integration
- **Dashboard**: Modern React-based admin dashboard
- **Queue System**: Redis-based queue for scalable email processing
- **Multi-tenant**: Support for multiple users with isolated data

## Tech Stack

- **Backend**: FastAPI (Python)
- **Frontend**: Next.js (React + TypeScript)
- **Database**: PostgreSQL
- **Queue**: Redis
- **SMTP**: Postfix
- **Containerization**: Docker & Docker Compose

## Quick Start

### One-Click Installation

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/your-repo/email-platform/main/install.sh | sudo bash

# Or clone and install manually
git clone https://github.com/your-repo/email-platform.git
cd email-platform
sudo ./install.sh
```

### Manual Installation

1. **Clone the repository**
```bash
git clone https://github.com/your-repo/email-platform.git
cd email-platform
```

2. **Configure environment variables**
```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env.local
# Edit the .env files with your settings
```

3. **Start with Docker Compose**
```bash
docker-compose up -d
```

4. **Access the dashboard**
- Dashboard: http://localhost:3000
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token

### Email Lists
- `GET /api/v1/lists` - Get all lists
- `POST /api/v1/lists` - Create list
- `GET /api/v1/lists/{id}` - Get list details
- `PUT /api/v1/lists/{id}` - Update list
- `DELETE /api/v1/lists/{id}` - Delete list
- `GET /api/v1/lists/{id}/contacts` - Get contacts
- `POST /api/v1/lists/{id}/contacts` - Add contact
- `POST /api/v1/lists/{id}/contacts/import` - Import CSV

### Campaigns
- `GET /api/v1/campaigns` - Get all campaigns
- `POST /api/v1/campaigns` - Create campaign
- `GET /api/v1/campaigns/{id}` - Get campaign details
- `PUT /api/v1/campaigns/{id}` - Update campaign
- `DELETE /api/v1/campaigns/{id}` - Delete campaign
- `POST /api/v1/campaigns/{id}/send` - Send campaign
- `POST /api/v1/campaigns/{id}/test` - Send test emails
- `GET /api/v1/campaigns/{id}/stats` - Get campaign stats

### Emails
- `GET /api/v1/emails` - Get all emails
- `POST /api/v1/emails/send` - Send single email
- `POST /api/v1/emails/send-bulk` - Send bulk emails
- `GET /api/v1/emails/stats` - Get email stats

### SMTP
- `GET /api/v1/smtp/domains` - Get SMTP domains
- `POST /api/v1/smtp/domains` - Add domain
- `POST /api/v1/smtp/domains/{id}/verify` - Verify domain
- `GET /api/v1/smtp/accounts` - Get SMTP accounts
- `POST /api/v1/smtp/accounts` - Create account

### Analytics
- `GET /api/v1/analytics/dashboard` - Get dashboard stats
- `GET /api/v1/analytics/email-volume` - Get email volume chart
- `GET /api/v1/analytics/engagement` - Get engagement stats
- `GET /api/v1/analytics/report` - Generate report

## SMTP Settings

Use these settings to send emails via SMTP:

- **Host**: Your domain or server IP
- **Port**: 587 (TLS) or 465 (SSL) or 25 (Plain)
- **Encryption**: TLS/SSL
- **Authentication**: Plain
- **Username**: Your SMTP account username
- **Password**: Your SMTP account password

## DNS Configuration

Configure these DNS records for your sending domain:

### SPF Record
```
v=spf1 include:your-domain.com ~all
```

### DKIM Record
Generate DKIM keys and add the public key to DNS:
```
default._domainkey.your-domain.com. IN TXT "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"
```

### DMARC Record
```
_dmarc.your-domain.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@your-domain.com"
```

### MX Record
```
your-domain.com. IN MX 10 mail.your-domain.com.
```

## Directory Structure

```
email-platform/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/            # API routes
│   │   ├── models/         # Database models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── main.py         # Application entry
│   ├── workers/            # Background workers
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/               # Next.js frontend
│   ├── src/
│   │   ├── app/           # Next.js app router
│   │   ├── components/    # React components
│   │   ├── contexts/      # React contexts
│   │   └── services/      # API services
│   ├── Dockerfile
│   └── package.json
├── database/              # Database files
├── install.sh            # One-click installer
├── docker-compose.yml    # Docker Compose config
└── README.md
```

## Management Commands

```bash
# Start all services
./start.sh

# Stop all services
./stop.sh

# Restart services
./restart.sh

# View logs
./logs.sh

# Check status
./status.sh

# Update to latest version
./update.sh
```

## Systemd Service

```bash
# Start service
systemctl start email-platform

# Stop service
systemctl stop email-platform

# Check status
systemctl status email-platform

# Enable auto-start
systemctl enable email-platform
```

## Environment Variables

### Backend

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Application secret key | Random |
| `DATABASE_URL` | PostgreSQL connection URL | - |
| `REDIS_URL` | Redis connection URL | - |
| `JWT_SECRET` | JWT signing secret | Random |
| `SMTP_HOST` | SMTP server host | localhost |
| `SMTP_PORT` | SMTP server port | 587 |
| `TRACKING_DOMAIN` | Domain for tracking links | localhost |

### Frontend

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_URL` | Backend API URL | http://localhost:8000/api/v1 |
| `NEXT_PUBLIC_TRACKING_DOMAIN` | Tracking domain | localhost |

## Scaling

### Horizontal Scaling

To scale the system horizontally:

1. **Add more workers**
```bash
docker-compose up -d --scale email-worker=4 --scale campaign-worker=2
```

2. **Use external Redis cluster**
Set `REDIS_URL` to point to your Redis cluster.

3. **Use external PostgreSQL**
Set `DATABASE_URL` to point to your PostgreSQL cluster.

### Performance Tuning

- Adjust `BULK_BATCH_SIZE` for optimal throughput
- Increase `BULK_WORKER_COUNT` for parallel processing
- Tune PostgreSQL connection pool size
- Use SSD storage for database

## Security

- All passwords are hashed with bcrypt
- JWT tokens for authentication
- API rate limiting
- CORS protection
- Input validation
- SQL injection protection via SQLAlchemy
- XSS protection in frontend

## Compliance

This platform is designed for legitimate email sending only:

- ✅ Opt-in email lists only
- ✅ Unsubscribe links required
- ✅ Bounce handling
- ✅ Complaint handling
- ✅ SPF/DKIM/DMARC support

## Troubleshooting

### Check service logs
```bash
docker-compose logs -f [service-name]
```

### Common issues

1. **Port already in use**
   - Change ports in `.env` file

2. **Database connection failed**
   - Check PostgreSQL is running
   - Verify DATABASE_URL

3. **Emails not sending**
   - Check Postfix logs
   - Verify SMTP settings
   - Check DNS records

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details

## Support

For support and questions:
- GitHub Issues: https://github.com/your-repo/email-platform/issues
- Documentation: https://docs.email-platform.com
- Email: support@email-platform.com

## Roadmap

- [ ] Webhook support
- [ ] Template editor
- [ ] A/B testing
- [ ] Advanced segmentation
- [ ] Multi-language support
- [ ] Mobile app
- [ ] Email validation API
- [ ] Deliverability monitoring
