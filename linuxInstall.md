# Linux Install Training - Skytap Environment

## Summary

This document is a proposed training for Partners. The goal is to provide a sandbox for practicing an install of Tableau Server on Linux. This training can be administered in Skytap, with 2 Linux VMs

Students will install Tableau Server on Linux, configure LDAP Authentication, and implement a basic Content Model, using three pre-defined groups in LDAP.

For a comprehensive guide to installing Tableau Server on Linux, refer to [Install and Configure Tableau Server](https://help.tableau.com/current/server-linux/en-us/install_config_top.htm).  

When finished, students will have:

* A running Tableau Server with LDAP Identity Store / Local Authentication
* SQL Server database with “Superstore World” and “DEV Superstore World”
* Practice reading in groups from LDAP
* Practice with the Linux Command Line
* Basic understanding of Content Model Best Practices


## Test Instance  

- Tableau Server (Hostname: **node2**)
    * XUbuntu Desktop 18.04 LTS, 32GB RAM, 8 Cores, 80GB Disk
    * uid/pw: **node2 / node2**
    * Tableau Server install (.deb) file on Desktop
    * **register.json**: JSON file for Registering Tableau Server via command line
    * **config.ldap.json**: JSON file to configure LDAP Identity Store (see below)
    * Apache Directory Studio (LDAP Browser) configured to connect to LDAP Server (see below)

- LDAP Server, SQL Server  (Hostname: **train-vm**)
    * Ubuntu Desktop 20.04 LTS, 8GB RAM, 4 Cores, 50GB Disk
    * uid/pw: **train / train**
    * LDAP Server (root: "dc=training,dc=com")
    * SQL Server
    * Apache Directory Studio (LDAP Browser)

## Part 0: Launch Environment

1. Press Power button in upper-right
1. Click on **Empty Ubuntu Image 30GB** to launch in your browser
1. Wait. It takes approximately 2 minutes to load the VM
1. Review Toolbar at top of screen.
1. Right-click the Desktop. Click **Open Terminal Here**


## Part 1: Prepare the Environment

### Update Linux Repositories 

Enter the following commands. Accept all prompts. **Note:** The "sudo" password is **node2**

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install gdebi-core
```

### Install Tableau Server Package

**Note**: The **LOC=** line below sets a bash variable, which is then used on the next line. This shortens the commands so they fit on one screen

```
sudo gdebi -n ~/Desktop/tableau-server-2021-1-0_amd64.deb
LOC=/opt/tableau/tableau_server/packages/
sudo $LOC/scripts.20211.21.0320.1853/initialize-tsm --accepteula
```

* exit Terminal (type "exit" or press Ctrl-D)
* Logout completely (select from menu)
* Open Terminal Window

### Apply License and Register

```
tsm licenses activate -k <your_license_key>
tsm register --file ~/Desktop/register.json
```

## Part 2: Configure LDAP

### Review LDAP Server Presentation 

Link to Google Slides: [LDAP and Tableau Server](https://docs.google.com/presentation/d/1rZk6ttog0vy7OnTyFrKQBOsp2IGvwZytrcV96cWA3ow/edit?usp=sharing)

### Test LDAP Connectivity  

```
ldapsearch -h train-vm \
-D "uid=admin,o=Users,dc=training,dc=com" \
-w admin -b "dc=training,dc=com"  
```

**Note**: The backslash at the end of each line lets you enter a command on multiple lines.


### Configure LDAP Identity Store

```
tsm settings import -f ~/Desktop/config.ldap.json 
tsm user-identity-store verify-user-mappings -v dev01
tsm user-identity-store verify-group-mappings -v Dev
```

## Part 3: Finish Installation

### Initialize Tableau Server 

```
tsm pending-changes apply
tsm initialize --start-server --request-timeout 1800
```

### Enable Metadata Services

```
tsm maintenance metadata-services enable
```

### Add Administrator

```
tabcmd initialuser \
--username 'admin' \
--password 'admin' \
--server http://localhost
```


## Part 4: Install SQL Server Driver (Linux)  

SQL is installed on *train-vm*. You have to install the SQL Server driver on the Tableau Server.  

### Install UnixOdbc Driver

At a terminal, enter the following (**node2** is the sudo password):  

```
sudo apt install unixodbc
```

### Install Tableau SQL Server Driver

* Go to [Driver Download](https://www.tableau.com/support/drivers)  
* Scroll to **Microsoft SQL Server**  
* Follow instructions under *On Debian and Ubuntu Linux distributions:*  
* Select Download the .deb file.  
* To install the driver, run the following command:  
```
sudo dpkg -i ~/Downloads/msodbcsql17_17.5.1.1-1_amd64.deb
```


## Part 5: Initial Configuration

### Content Model / Do this First

* Login as Server Administrator (admin / admin)
* Modify Permissions for Default Project. Remove ALL permissions from the **All Users** Group

## Part 6: Groups and Permissions

### Import Finance Group

* Create Finance Project 
	* Click **Explore**
	* Click **New** -> **Project**
	* Enter **Finance**
	* Click **Create**
	
* Import Finance Group  
	* Click **Groups**
	* Click **Add Group**; Select **Active Directory Group**
	* In the search bar, enter **Finance**. Select it
	* Set all to **Creator** (dropdown list)
	* Click **Import**

### Set Permissions for Finance Group  

* Check Permissions for Finance01 User (Optional)
	* Sign Out
	* Sign in **User**: Finance01 **Password**: Tableau
	* Can you see the *Finance* Project? Why not?
	
	
* Modify Permissions on Finance Project
	* Sign in as Administrator (admin / admin)
	* Click **Explore**
	* Click on three dots "..." for the **Finance** Project
	* Select **Permissions**
	* For each group of Permissions, Select **Publish** from the **Template** drop-down
	* Click *Save*. Note the updated **Effective Permissions** at the bottom

* Check Permissions for Finance01 User (Optional)
	* Sign Out
	* Sign in **User**: Finance01 **Password**: Tableau
	* Can you see the **Finance** Project?


## References

* [Get Started with Tableau Server on Linux](https://help.tableau.com/current/server-linux/en-us/get_started_server.htm)
* [Jump-Start Installation](https://help.tableau.com/current/server-linux/en-us/jumpstart.htm)
* [Install and Configure Tableau Server](https://help.tableau.com/current/server-linux/en-us/install_config_top.htm)
* [Driver Download](https://www.tableau.com/support/drivers)
* [Post Installation Tasks](https://help.tableau.com/current/server-linux/en-us/config_post_install.htm)


## Appendix

### Timings / Planning the Training

Here are some rough timings for steps in the training. Note the **Initialize** step can take up to 15 minutes. 

- Install .deb file. **1:30**
- Activate License. **:25**
- Register. **1:10**
- Apply pending changes. **:34**
- Initialize. **14:00**. One option is to present Content Model Best Practices during this time.

### Registration JSON File  

```
{
  "zip" : "98103",
  "country" : "United States",
  "city" : "Seattle",
  "last_name" : "Biden",
  "industry" : "Software",
  "eula" : "yes",
  "title" : "President and CEO",
  "phone" : "555-123-4567",
  "company" : "Tableau",
  "state" : "Washington",
  "department" : "Sales",
  "first_name" : "Joe",
  "email" : "info@tableau.com"
}

```




### LDAP Identity Store JSON File  

```
{
    "configEntities": {
        "identityStore": {
            "_type": "identityStoreType",
            "type": "activedirectory",
            "domain": "train-vm",
            "root": "",
            "nickname": "",
            "hostname": "train-vm",
            "port": "389",
            "sslPort": "",
            "directoryServiceType": "openldap",
            "bind": "simple",
            "username": "uid=admin,o=Users,dc=training,dc=com",
            "password": "changeme",
            "kerberosPrincipal": "",
            "identityStoreSchemaType": {
                "distinguishedNameAttribute": "",
                "userBaseDn": "o=Users,dc=training,dc=com",
                "userBaseFilter": "objectClass=inetOrgPerson",
                "userUsername": "uid",
                "userClassNames": ["inetOrgPerson"],
                "userDisplayName": "givenName",
                "userEmail": "mail",
                "userCertificate": "",
                "userThumbnail": "",
                "userJpegPhoto": "",
                "memberOf": "member",
                "member": "member",
                "groupBaseDn": "o=Groups,dc=training,dc=com",
                "groupBaseFilter": "objectClass=groupofNames",
                "groupName": "cn",
                "groupEmail": "",
                "groupDescription": "description",
                "serverSideSorting": "false",
                "rangeRetrieval": "false",
                "membersRetrievalPageSize": ""

            }
        }
    }
}
```

