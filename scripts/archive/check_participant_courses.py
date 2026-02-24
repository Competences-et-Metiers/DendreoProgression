#!/usr/bin/env python3
import psycopg2
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_participant_courses():
    try:
        conn = psycopg2.connect(
            host='localhost',
            database='dendreo_db',
            user='postgres',
            password='postgres'
        )
        cur = conn.cursor()
        
        print("=== PARTICIPANT_COURSES TABLE ANALYSIS ===")
        
        # Check table structure
        cur.execute("""
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'participant_courses' 
            ORDER BY ordinal_position
        """)
        columns = cur.fetchall()
        print("\nTable structure:")
        for col in columns:
            print(f"  {col[0]}: {col[1]} (nullable: {col[2]})")
        
        # Check total records
        cur.execute("SELECT COUNT(*) FROM participant_courses")
        total_count = cur.fetchone()[0]
        print(f"\nTotal participant_courses records: {total_count}")
        
        # Check last_activity null values
        cur.execute("SELECT COUNT(*) FROM participant_courses WHERE last_activity IS NULL")
        null_count = cur.fetchone()[0]
        print(f"Records with NULL last_activity: {null_count} ({100*null_count/total_count:.1f}%)")
        
        # Check last_activity non-null values
        cur.execute("SELECT COUNT(*) FROM participant_courses WHERE last_activity IS NOT NULL")
        non_null_count = cur.fetchone()[0]
        print(f"Records with non-NULL last_activity: {non_null_count}")
        
        if non_null_count > 0:
            cur.execute("SELECT last_activity FROM participant_courses WHERE last_activity IS NOT NULL ORDER BY last_activity DESC LIMIT 5")
            samples = cur.fetchall()
            print("\nSample last_activity values (most recent first):")
            for sample in samples:
                print(f"  {sample[0]}")
        
        # Check modules with lms_last_access_at
        print("\n=== MODULES ANALYSIS ===")
        cur.execute("SELECT COUNT(*) FROM modules")
        total_modules = cur.fetchone()[0]
        print(f"Total modules: {total_modules}")
        
        cur.execute("SELECT COUNT(*) FROM modules WHERE lms_last_access_at IS NOT NULL")
        modules_with_access = cur.fetchone()[0]
        print(f"Modules with lms_last_access_at: {modules_with_access}")
        
        if modules_with_access > 0:
            cur.execute("SELECT lms_last_access_at FROM modules WHERE lms_last_access_at IS NOT NULL ORDER BY lms_last_access_at DESC LIMIT 5")
            module_samples = cur.fetchall()
            print("\nSample module lms_last_access_at values (most recent first):")
            for sample in module_samples:
                print(f"  {sample[0]}")
        
        # Check relationship between participant_courses and modules
        print("\n=== RELATIONSHIP ANALYSIS ===")
        cur.execute("""
            SELECT pc.id, pc.participant_id, c.id_action_formation, 
                   COUNT(m.id) as module_count,
                   COUNT(CASE WHEN m.lms_last_access_at IS NOT NULL THEN 1 END) as modules_with_access
            FROM participant_courses pc
            JOIN courses c ON pc.course_id = c.id
            LEFT JOIN modules m ON m.participant_id = pc.participant_id 
                              AND m.id_lam IN (
                                  SELECT c2.id_lam 
                                  FROM courses c2 
                                  WHERE c2.id_action_formation = c.id_action_formation
                              )
            GROUP BY pc.id, pc.participant_id, c.id_action_formation
            HAVING COUNT(m.id) > 0
            LIMIT 5
        """)
        sample_relationships = cur.fetchall()
        print("\nSample participant-course-module relationships:")
        print("PC_ID | PARTICIPANT_ID | ADF_ID | MODULE_COUNT | MODULES_WITH_ACCESS")
        for rel in sample_relationships:
            print(f"{rel[0]:5} | {rel[1]:13} | {rel[2]:6} | {rel[3]:12} | {rel[4]:17}")
        
        cur.close()
        conn.close()
        
        print("\n✅ Analysis completed!")
        
    except Exception as e:
        logger.error(f"Error during analysis: {str(e)}")
        return False
    
    return True

if __name__ == "__main__":
    check_participant_courses() 