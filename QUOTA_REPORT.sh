#! /bin/bash

# Les partitions créées
HOME_PARTITION="/dev/nvme0n1p7"
DATA_PARTITION="/dev/nvme0n1p6"
DATE=$(date)
# Points de montages
HOME_MOUNT_POINT="/HOME_TEST"
DATA_MOUNT_POINT="/data"

# Chemin absolu du script
SCRIPT_PATH="/home/andrianina/S2/sys/SCRIPT/QUOTA_REPORT.sh"
#Creation des fichier de configuration des quotas
quota_configuration(){

	quotacheck -cu $HOME_MOUNT_POINT
	quotacheck -cu $DATA_MOUNT_POINT

	#Activation des quotas
	quotaon $HOME_MOUNT_POINT
	quotaon $DATA_MOUNT_POINT

	all_users=$(cat /etc/passwd | grep "/bin/bash" | awk -F: '{ print $1 }')

	#Initialisation des quotas pour chaque utilisateur
	for USER in $all_users; do
		setquota -u $USER 512000 716800 0 0 $HOME_MOUNT_POINT 
		setquota -u $USER 0 0 500 700 $DATA_MOUNT_POINT
	done
}

#Edition du fichier /etc/fstab
writing_on_fstab(){
	#Verification dans le fichier /etc/fstab
	check_home=$( cat /etc/fstab | grep -c $HOME_PARTITION )
	check_data=$( cat /etc/fstab | grep -c $DATA_PARTITION )

	result=$(($check_home + $check_data)) 

	#Si les partitions ne sont pas dans le fstab, on les ajoute
	if [ $result -ne 2 ]; then
		echo "$HOME_PARTITION	$HOME_MOUNT_POINT	ext4	defaults,usrquota	0	2" >> /etc/fstab
		echo "$DATA_PARTITION	$DATA_MOUNT_POINT	ext4	defaults,usrquota	0	2" >> /etc/fstab
	
		quota_configuration
	fi

}

checking_repquota(){

	#Vérification des quotas
	repquota $HOME_MOUNT_POINT > /tmp/HOME_TEST_report.check
	repquota $DATA_MOUNT_POINT > /tmp/data_report.check
	
	#Analyse des rapports de quotas
	quota_used_for_HOME=$(cat /tmp/HOME_TEST_report.check | awk 'NR > 5 { print $3 }')
	quota_fixed_for_HOME=$(cat /tmp/HOME_TEST_report.check | awk 'NR ==  6{ print $4 }')
	quota_used_for_DATA=$(cat /tmp/data_report.check | awk 'NR > 5 { print $7 }')
	quota_fixed_for_DATA=$(cat /tmp/data_report.check | awk 'NR == 6  { print $8 }')

	users=$(cat /tmp/HOME_TEST_report.check | awk 'NR > 5 { print $1 }')

	#Envoi d'un mail d'alerte si le quota est atteint
	for quota_value in $quota_used_for_HOME; do
		if [ $quota_value -ge $quota_fixed_for_HOME ]; then 
			for USER in $users; do
				echo "$DATE : L'utilisateur $USER a atteint sa limite de quota sur la partition $HOME_MOUNT_POINT" > /var/mail/$USER
				echo "* * * * * root /bin/bash  echo $DATE : L'utilisateur $USER a atteint sa limite de quota sur la partition $HOME_MOUNT_POINT" >> /etc/crontab
			done	
		elif [ $quota_fixed_for_HOME -ge $quota_value ]; then
			for USER in $users; do
				echo "$DATE : L'utilisateur $USER peut encore ecrire dans $HOME_MOUNT_POINT" >> /var/mail/$USER
			done	
		fi
	done
	
	for quota_value in $quota_used_for_DATA; do
		if [ $quota_used_for_DATA -ge $quota_fixed_for_DATA ]; then
			for USER in $users; do
				echo "$DATE : L'utilisateur $USER a atteint sa limite de quota sur la partition $DATA_MOUNT_POINT" > /var/mail/$USER
				echo "* * * * * root /bin/bash  echo $DATE : L'utilisateur $USER a atteint sa limite de quota sur la partition $DATA_MOUNT_POINT" >> /etc/crontab
			done	
		elif [ $quota_fixed_for_DATA -ge $quota_value ]; then
			for USER in $users; do
				echo "$DATE : Limite non atteinte pour l'utilisatuer $USER peut encore ecrire dans $DATA_MOUNT_POINT" > /var/mail/$USER
			done	
		fi
	done	
}
# Edition de /etc/crontab pour planifier l'exécution du script chaque lundi à minuit
cron_planification(){

	#Vérification de la présence du script dans le crontab
	check_cron=$( cat /etc/crontab | grep -c "QUOTA_REPORT.sh")

	if [ $check_cron -eq 0 ]; then
	echo "0 9 * * 1	root	/bin/bash $SCRIPT_PATH" >> /etc/crontab
	fi
}

writing_on_fstab
checking_repquota
cron_planification
