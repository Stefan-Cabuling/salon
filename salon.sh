#!/bin/bash

# PostgreSQL command shortcut
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

# Ensure tables exist
$PSQL "
  CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    phone VARCHAR UNIQUE NOT NULL
  );

  CREATE TABLE IF NOT EXISTS services (
    service_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL
  );

  CREATE TABLE IF NOT EXISTS appointments (
    appointment_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    service_id INT REFERENCES services(service_id),
    time VARCHAR NOT NULL
  );
"

# Insert default services
$PSQL "
  INSERT INTO services (service_id, name) VALUES
    (1, 'cut'),
    (2, 'color'),
    (3, 'style')
  ON CONFLICT (service_id) DO NOTHING;
"

# Function to display services
display_services() {
  echo -e "\nAvailable Services:"
  $PSQL "SELECT service_id, name FROM services ORDER BY service_id" | while IFS="|" read -r SERVICE_ID NAME; do
    echo "$SERVICE_ID) $NAME"
  done
}

# Prompt for a valid service ID
while true; do
  display_services
  echo "Enter the service ID:"
  read SERVICE_ID_SELECTED

  # Validate service
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED" | xargs)
  if [[ -n "$SERVICE_NAME" ]]; then
    break
  else
    echo -e "\nInvalid service ID. Please try again."
  fi
done

# Get customer phone number
echo "Enter your phone number:"
read CUSTOMER_PHONE

# Check if customer exists
CUSTOMER_INFO=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")

if [[ -z "$CUSTOMER_INFO" ]]; then
  echo "New customer! Enter your name:"
  read CUSTOMER_NAME

  # Insert new customer
  $PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')"
  
  # Get new customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
else
  CUSTOMER_ID=$(echo "$CUSTOMER_INFO" | cut -d '|' -f1)
  CUSTOMER_NAME=$(echo "$CUSTOMER_INFO" | cut -d '|' -f2)

  # Explicitly ensure CUSTOMER_NAME is assigned
  if [[ -z "$CUSTOMER_NAME" ]]; then
    CUSTOMER_NAME="Customer"
  fi
fi

# Get appointment time
echo "Enter appointment time (e.g., 10:30 AM):"
read SERVICE_TIME

# Insert appointment
$PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')"

# Confirmation message
echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."

# Ensure script exits properly
exit 0
