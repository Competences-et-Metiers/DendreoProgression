# 🚀 DendreoProgression Production Deployment Guide

## 📋 New Database Columns Added

The following new columns have been added to support time tracking functionality:

### **Courses Table**
- `planned_duration_hours` (FLOAT) - Planned duration in hours from `duree_heures`

### **Modules Table**
- `lms_time_spent` (INTEGER) - Time spent in seconds by participant
- `lms_started_at` (TIMESTAMP WITH TIME ZONE) - When participant started the module
- `lms_completed_at` (TIMESTAMP WITH TIME ZONE) - When participant completed the module

## 🔧 Production Deployment Steps

### **Step 1: Prepare Migration Files**

Copy these files to your Debian production server:
- `database/migrations/001-add-time-tracking-columns.sql`
- `scripts/deploy-migration.sh`

### **Step 2: Update Database Configuration**

Edit `scripts/deploy-migration.sh` and update these variables:
```bash
DB_HOST="your-production-db-host"
DB_PORT="5432"
DB_NAME="your-production-db-name"
DB_USER="your-production-db-user"
DB_PASSWORD="your-production-db-password"
```

### **Step 3: Make Script Executable**

On your Debian server:
```bash
chmod +x scripts/deploy-migration.sh
```

### **Step 4: Run Migration**

On your Debian server:
```bash
./scripts/deploy-migration.sh
```

The script will:
- ✅ Test database connection
- ✅ Create a backup automatically
- ✅ Add new columns safely (won't duplicate if they exist)
- ✅ Create necessary indexes
- ✅ Verify the migration

### **Step 5: Restart Application**

After successful migration:
```bash
# Restart your application containers
docker-compose restart backend
docker-compose restart frontend
```

### **Step 6: Run Sync**

Trigger a sync to populate the new time tracking data:
```bash
# Run your sync container/script
docker-compose run sync python sync_script.py
```

## 🔍 Verification Commands

### **Check New Columns Exist**
```sql
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('courses', 'modules') 
AND column_name IN ('planned_duration_hours', 'lms_time_spent', 'lms_started_at', 'lms_completed_at')
ORDER BY table_name, column_name;
```

### **Check Time Tracking Data**
```sql
SELECT 
    COUNT(*) as total_modules,
    SUM(lms_time_spent) as total_time_spent,
    COUNT(CASE WHEN lms_time_spent > 0 THEN 1 END) as modules_with_time
FROM modules;
```

### **Check Planned Duration Data**
```sql
SELECT 
    COUNT(*) as total_courses,
    COUNT(CASE WHEN planned_duration_hours > 0 THEN 1 END) as courses_with_planned_duration,
    AVG(planned_duration_hours) as avg_planned_duration
FROM courses;
```

## ⚠️ Important Notes

1. **Backup**: The migration script creates an automatic backup
2. **Safe**: The migration is idempotent (can be run multiple times safely)
3. **Downtime**: Minimal downtime - just restart containers after migration
4. **Data**: Existing data is preserved, new columns start with default values

## 🆘 Troubleshooting

### **If Migration Fails**
1. Check database connection settings
2. Verify PostgreSQL client tools are installed
3. Ensure database user has ALTER TABLE permissions
4. Check the backup file was created

### **If Columns Already Exist**
The migration is safe to run multiple times - it will skip existing columns.

### **If No Time Data Appears**
1. Ensure sync has been run after migration
2. Check that `lms_tempspasse` data exists in Dendreo API responses
3. Verify the sync process is processing time tracking data

## 📞 Support

If you encounter issues:
1. Check the migration logs for specific error messages
2. Verify database permissions and connectivity
3. Restore from backup if needed: `psql -f dendreo_backup_YYYYMMDD_HHMMSS.sql`
