#!/bin/bash
#
#  Usage:   make-user.sh  
#
#  2011 November - Austin Murphy
#  2012 April - Austin Murphy
#
#  A simple user creation script for delegated administrators.
# 
#    - All user info is entered interactively
#    - checks that user does not yet exist
#    - generates and sets a password 
#    - reports the SUDO_USER who ran the script
# 
#


#
# INSTALL 
#
#  1. Copy this script into /usr/local/bin on the server in question.
#  2. Chamge the mode to 700 and the owner to root:root
#  3. Using sudo, give the delegated admins permission to run this script.
#  4. Edit the $TO variable below to send notifications to the right people.
#  5. Customize the $ACCTNAMETEXT for your site.
#
#


#########################################
#
#  Basics
#
#########################################


# System Administrator(s) of record for this system and the system owner
#
TO="sysadmin@example.com sysowner@example.com"

# This text is displayed to the user before they enter the username of 
#  the account to be created.
#
ACCTNAMETEXT="Enter the name of the account to create.  \nThis should be the user's or their sponsor's site-wide user ID: "


######################


USERADD="/usr/sbin/useradd"
PWGEN="/usr/local/bin/pwgen"
CHPASSWD="/usr/sbin/chpasswd"

# Only root can run this script (or sudo-ers)
[[ $UID -eq 0 ]] || { echo "ERROR -- This script must be run as root or with sudo. " && exit 1 ;}

# Account Creator
if [ "X$SUDO_USER" == "X" ]
then
  cr_user=root 
  cr_uid=0
else
  cr_user=$SUDO_USER
  cr_uid=$SUDO_UID
fi


#########################################
#
#  Gather info
#
#########################################


HOSTNAME=$(/bin/hostname -s | /usr/bin/tr -t a-z A-Z)

# get user account name
echo -e "\n\n\n"
echo -en "$ACCTNAMETEXT"
read user

[[ "X${user}X" == "XX" ]] && echo "*** ERROR -- No username given! " && exit 

#  exists?
/usr/bin/id $user 2> /dev/null > /dev/null 
USTAT=$?
[[ $USTAT -eq 1 ]] || { echo "ERROR -- User exists!  Use a different username or contact your system administrator. " && exit 1 ;}


# get full name of user
echo -e "\n\n\n"
echo -n "Enter full name or a comment for $user: "
read userdesc

[[ "X${userdesc}X" == "XX" ]] && echo "*** ERROR -- No full name or comment given! " && exit 


# password
pass=$($PWGEN -nc1)


echo "

Is this correct: 

            Host Name:  $HOSTNAME
         Account Name:  $user
 Full Name or Comment:  $userdesc

          (y|N) ?"
read CORRECT
[[ $CORRECT == 'y' ]] || [[ $CORRECT == 'Y' ]] || { echo "No action taken. Try again." && exit 1 ;}

echo -e "\n\n\n"



#########################################
#
#  Create account
#
#########################################


# add user account
$USERADD -m -s /bin/bash -c "$userdesc" $user

uid=$(id -u $user)


# set password
echo "Setting password for $user ..."
echo "$user:$pass" | $CHPASSWD -m 




#########################################
#
#  Report what happened
#
#########################################


mail -s "New user on $HOSTNAME: $user" $TO <<EOM
A new user account has been created.

      Server:  $HOSTNAME 
     Account:  $user  ($uid)
   Full name:  $userdesc

  Created by:  $cr_user ($cr_uid).

EOM

echo -e "\n\n\n"

echo ""
echo "  New user on $HOSTNAME has been created."
echo ""
echo "               user :  $user  ($userdesc) "
echo "           password :  $pass"
echo ""
echo " User can change password by running:  passwd  "
echo ""
echo " !!! DO NOT SEND PASSWORDS BY EMAIL !!!"
echo ""

echo -e "\n\n\n"



#  
#  END 
#
