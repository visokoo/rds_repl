# RDS_REPL
The purpose of this script is to be used on an instance responsible for restoring the initial backup of your database on your RDS replica. Due to the nature of how RDS works on AWS, if you try a vanilla restore of your mysqldump, it will fail due to the super privilege statements. This script serves to remove all of that in your dump file and initiates the replication for you.
