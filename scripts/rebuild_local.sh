#!/bin/bash

set -e

echo "Stopping Supabase Lite..."
supabase-lite stop || true

echo "Removing local data directory..."
rm -rf ./supabase/.data

echo "Starting Supabase Lite..."
supabase-lite start

echo "Waiting for database to become ready..."
sleep 3

echo "Applying migrations..."
for file in db/migrations/*.sql; do
  echo "Running migration: $file"
  supabase-lite db execute --file "$file"
done

echo "Applying base seed..."
supabase-lite db execute --file db/seed/base_seed.sql

echo "Applying dev seed..."
supabase-lite db execute --file db/seed/dev_seed.sql

echo "Local rebuild complete."
