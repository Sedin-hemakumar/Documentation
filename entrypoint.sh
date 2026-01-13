#📘 Docker entrypoint.sh – Complete Documentation (Beginner → Interview Level)

This document explains why the entrypoint exists, what each line does, and how it works together with Docker CMD and Rails database migrations.<br>

🔹 What is entrypoint.sh?

entrypoint.sh is a startup script that runs every time the container starts, before the Rails application server (Puma) is launched.<br>

Its job is to:
Decide the environment (dev / test / prod)<br>
Fetch secrets from AWS Secrets Manager<br>
Export environment variables for Rails<br>
Wait until the database is ready<br>
Prepare the database (create + migrate)<br>
Start the Rails app using Puma<br>

##📄 Full entrypoint.sh
'''
#!/usr/bin/env bash
set -e

# Default to dev if ENVIRONMENT is not set
ENVIRONMENT=${ENVIRONMENT:-dev}

if [ "$ENVIRONMENT" = "test" ]; then
  SECRET_NAME="test/secret/hemath"
else
  SECRET_NAME="rds/secret/hemath"
fi

REGION="ap-south-1"

echo "Fetching secrets from AWS Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --region $REGION \
  --query SecretString \
  --output text)

# Parse JSON fields
DB_USERNAME=$(echo $SECRET_JSON | jq -r .DB_USERNAME)
DB_PASSWORD=$(echo $SECRET_JSON | jq -r .DB_PASSWORD)
DB_HOST=$(echo $SECRET_JSON | jq -r .DB_HOST)
DB_PORT=$(echo $SECRET_JSON | jq -r .DB_PORT)
DB_NAME=$(echo $SECRET_JSON | jq -r .DB_NAME)
RAILS_ENV=$(echo $SECRET_JSON | jq -r .RAILS_ENV)
SECRET_KEY_BASE=$(echo $SECRET_JSON | jq -r .SECRET_KEY_BASE)

export DB_USERNAME DB_PASSWORD DB_HOST DB_PORT DB_NAME RAILS_ENV SECRET_KEY_BASE

echo "Using DB: $DB_NAME at $DB_HOST:$DB_PORT with user $DB_USERNAME"

echo "Waiting for DB..."
until bundle exec rails db:version >/dev/null 2>&1; do
  echo "  Database not ready. Retrying in 2s..."
  sleep 2
done

echo "Database is ready!"
echo "Running migrations..."
bundle exec rails db:prepare

exec "$@"

'''
#🧩 Line-by-Line Explanation

##1️⃣ Shebang – how the script runs
'''
#!/usr/bin/env bash
'''

Why this is used ?
Runs the script using bash<br>
Portable across Linux distributions<br>
Safer than hardcoding /bin/bash<br>

##2️⃣ Exit on error
'''
set -e
'''
Meaning
If any command fails, the script stops immediately <br>
Why important ? <br>
Prevents app from starting with:<br>
Missing secrets<br>
Broken DB connection<br>
Invalid configuration<br>

#📌 Interview keyword: Fail fast

##3️⃣ Default environment selection
'''
ENVIRONMENT=${ENVIRONMENT:-dev}
'''
What it does ?
If ENVIRONMENT is not set → defaults to dev<br>

Example:

ENVIRONMENT	Result<br>
not set	dev<br>
test	test<br>
prod	prod<br>

#📌 Allows one Docker image for all environments

##4️⃣ Environment-based secret selection
'''
if [ "$ENVIRONMENT" = "test" ]; then
  SECRET_NAME="test/secret/hemath"
else
  SECRET_NAME="rds/secret/hemath"
fi
'''
Why this exists ?<br>
Test DB ≠ Production DB<br>
Prevents accidental prod DB access<br>
Clean environment separation<br>

#📌 Interview keyword: Environment isolation

##5️⃣ AWS Region configuration
'''
REGION="ap-south-1"
'''

Why needed ?<br>
AWS Secrets Manager is region-specific<br>
AWS CLI must know where to fetch secrets<br>
##
#6️⃣ Fetch secrets from AWS Secrets Manager
'''
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --region $REGION \
  --query SecretString \
  --output text)
  '''
What happens here ?
AWS CLI fetches the secret<br>
Only the secret value (SecretString) is returned<br>
Stored as JSON in SECRET_JSON<br>
'''
Example secret
{
  "DB_USERNAME": "rails",
  "DB_PASSWORD": "password",
  "DB_HOST": "db.example.com",
  "DB_PORT": "5432",
  "DB_NAME": "app_db",
  "RAILS_ENV": "production",
  "SECRET_KEY_BASE": "abc123"
}
'''

#📌 Interview keyword: Secrets externalization

##7️⃣ Parsing secrets using jq
'''
DB_USERNAME=$(echo $SECRET_JSON | jq -r .DB_USERNAME)

'''
Why jq ?
AWS returns JSON <br>
jq extracts exact fields<br>
-r removes quotes<br>
'''
Example
echo '{"DB_NAME":"mydb"}' | jq -r .DB_NAME
Output:
mydb
'''

#8️⃣ Export environment variables

'''
export DB_USERNAME DB_PASSWORD DB_HOST DB_PORT DB_NAME RAILS_ENV SECRET_KEY_BASE
'''
Why export is required<br>
Makes variables available to:<br>
Rails<br>
ActiveRecord<br>
Puma<br>
Child processes inherit these variables<br>

##📌 Without export, Rails cannot see them
'''

9️⃣ Safe logging
echo "Using DB: $DB_NAME at $DB_HOST:$DB_PORT with user $DB_USERNAME"
'''
Why this is safe
Confirms correct DB is used
Does NOT log passwords

##📌 Interview keyword: Secure logging
#🔄 Database Readiness Check (VERY IMPORTANT)
#🔟 DB wait loop (deep explanation)
'''
until bundle exec rails db:version >/dev/null 2>&1; do
'''
What until means?

Run the loop until the command succeeds<br>
What rails db:version does? <br>
Loads Rails app<br>
Tries to connect to DB<br>
Reads schema migration version<br>
Exits immediately<br>

✔ Success → DB is ready<br>
❌ Failure → DB not ready<br>

Why output is suppressed?
>/dev/null 2>&1<br>
>/dev/null → discard normal output<br>
2>&1 → discard error output<br>
Keeps logs clean<br>
Full loop behavior<br>
'''
until bundle exec rails db:version; do
  sleep 2
done
'''
Meaning:
“Keep retrying DB connection every 2 seconds until it works.”<br>
##📌 Interview keyword: Dependency readiness check
🗄️ Database Preparation<br>
#1️⃣1️⃣ db:prepare (IMPORTANT)
'''
bundle exec rails db:prepare
'''
What db:prepare does
It automatically:<br>
Creates DB if missing<br>
Loads schema if needed<br>
Runs pending migrations<br>
Does nothing if already up-to-date<br>

Why not db:migrate?<br>
Command	Issue<br>
db:migrate	Fails if DB doesn’t exist
db:setup	Dangerous in prod
db:prepare	Safe everywhere

##📌 Best command for Docker & ECS
##🚀 Starting the Application
#1️⃣2️⃣ exec "$@"
'''
exec "$@"
'''
What $@ means?
All arguments passed from Docker CMD<br>

From Dockerfile:<br>
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]<br>
So $@ becomes:<br>
bundle exec puma -C config/puma.rb<br>
Why exec is critical<br>
Replaces shell with Puma<br>
Puma becomes PID 1<br>
Signals (SIGTERM) handled correctly<br>
Graceful shutdown in Docker / ECS<br>
📌 Interview keyword: Proper signal handling<br>
🧠 ENTRYPOINT + CMD (Interview Gold)<br>
'''
Dockerfile:
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
'''
Docker runs:
'''
entrypoint.sh bundle exec puma -C config/puma.rb
'''
#❌ This is NOT docker exec
Concept	Meaning<br>
ENTRYPOINT + CMD	Run at container startup<br>
docker exec	Run inside already running container<br>
'''
🔁 Full Startup Flow (Memorize This)
Container starts
   ↓
entrypoint.sh runs
   ↓
Environment selected
   ↓
Secrets fetched
   ↓
Env vars exported
   ↓
Wait for DB
   ↓
db:prepare
   ↓
Puma starts
   ↓
Rails app is live

'''
🏁 One-Page Interview Summary<br>
Key points to say in interviews:<br>
ENTRYPOINT prepares the container<br>
CMD defines how the app runs<br>
Secrets are fetched at runtime<br>
DB readiness is checked using Rails itself<br>
db:prepare is safe for all environments<br>
exec "$@" ensures proper shutdown<br>
Puma runs Rails in production<br>
🧠 One-line takeaway (final)<br>
This entrypoint ensures the container starts safely, securely, and consistently by preparing the environment and database before launching Rails with Puma.