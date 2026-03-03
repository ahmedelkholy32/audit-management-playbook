audit-management-playbook
=========================

Manage audit service on all/certain servers. Such as:

- Install the auditd package.
- Ensure the auditd service is enabled.
- Add the `update-audit-rules.sh` script to update the audit rules for auditing users’ commands.

Playbook Structure
------------------

    audit-management-playbook
    ├── ansible.cfg
    ├── ansible.cfg.example
    ├── audit-management.yml
    ├── files
    │   └── update-audit-rules.sh
    ├── .git
    ├── .gitignore
    ├── inventory
    ├── inventory.example
    └── README.md

Playbook Variables
------------------

| Variable | Mandatory | Default | Ex | Description |
|:--------:|:---------:|:-------:|:--:|:-----------:|
| servers  | no | all | servers=group1,host1 | list of hosts and groups where tasks should be run. This list should be selected from inventor |

Playbook Syntax
---------------

Initialize the audit service on all servers:

    ansible-playbook audit-management.yml

Initialize the audit service on specific groups or hosts:

    ansible-playbook audit-management.yml -e servers=<group1,host1,..>

License
-------

BSD-3-Clause

Author Information
------------------

- Author: Ahmed Elkholy
- Email: <ahmedelkholy89@gmail.com>
