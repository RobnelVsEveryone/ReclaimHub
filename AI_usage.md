# AI Usage

This project used **Claude (Anthropic)** as an AI assistant during development.

## How it was used
- Setting up WebSocket integration for real-time CRUD broadcasting
- Writing JWT authentication and role-based middleware (admin vs user)
- Building the audit trail system — logging who did what and when
- Generating the database schema and seed data (`db_dump.sql`) with 150+ dummy records
- Debugging bcrypt password hashing issues with seeded users
- Fixing live WebSocket updates for metric cards, activity feed, and item tables
- Connecting the frontend to the backend API (replacing hardcoded dummy data with real `fetch()` calls)
- Writing the Leaflet.js map integration for lost item pin-drop feature
- Code review, refactoring, and bug fixing throughout development

## What was not AI-generated

- Project idea and system concept
- Database design decisions and table relationships
- Choice of tech stack (Node.js, MySQL, WebSocket, Leaflet)
- Manual testing and validation of all features
- Deployment and local environment setup (XAMPP, Node)
- Final review and integration of all generated code

## Note

AI was used as a development tool — similar to using Stack Overflow or documentation.
All generated code was reviewed, understood, tested, and integrated by the developer.