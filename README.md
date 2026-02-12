
# AD-Group-Flattening

PowerShell automation toolkit for analyzing, exporting, and flattening complex Active Directory group structures.

This repository contains a modular PowerShell solution designed to handle real-world Active Directory (AD) challenges such as nested group memberships, unclear access paths, and missing documentation.

The project is part of my personal learning journey towards **Automation Engineering** and serves as a portfolio project to demonstrate practical PowerShell automation skills.

---

## Overview

In many Active Directory environments, group memberships are deeply nested, making audits, migrations, and access reviews difficult and error-prone.

This project helps to:

- Analyze nested AD group structures
- Export group hierarchies as backups
- Evaluate all effective users of a group (direct and indirect)
- Flatten group memberships for easier management
- Log and document all actions for traceability

---

## Features

- **Recursive Group Backup**  
  Creates a hierarchical JSON backup of group structures.

- **Membership Evaluation**  
  Resolves all nested group members and produces a flat user list.

- **Flattening & Comparison**  
  Compares direct vs. indirect members and prepares flattened results.

- **Optional Cleanup**  
  Allows removal of subgroups after user extraction.

- **Centralized Logging**  
  Structured logging with timestamps, log levels, and log rotation.

---

## Repository Structure

```text

PS_ActiveDirectory_Flattening/
│
├── config/
│   └── config.json                 # Configuration for paths and output
│
├── modules/
│   ├── log.psm1                   # Logging functions
│   ├── backup.psm1                # Group structure backup logic
│   ├── evaluation.psm1            # Nested member evaluation
│   └── comparison.psm1            # Flattening and comparison logic
│
├── Script.ps1                     # Main orchestration script
├── LICENSE                        # MIT License
└── README.md                      # Documentation

````
## Configuration & Directories

This project uses a configuration file to define all output and working directories.

The following directories are **configured via `config/config.json`** and are created or used automatically during script execution.

| Directory   | Description |
|------------|-------------|
| `backup/`      | Stores JSON backups of Active Directory group hierarchies |
| `evaluation/`  | Contains evaluated and flattened group membership reports |
| `log/`         | Stores execution logs with timestamps and log levels |
| `result/`      | Contains comparison and final result files |

All directory paths can be adjusted in the configuration file: `config/config.json`

This Directorystructure allows flexible reuse of the script across different environments without modifying the code.

---

## Requirements

- Windows PowerShell 5.1 or later
- ActiveDirectory PowerShell module (RSAT)
- Permissions to read and modify Active Directory groups

---

## Usage

1. Clone the repository:

```bash
git clone https://github.com/PWRScripting/AD-Group-Flattening.git
cd AD-Group-Flattening
````

2. Adjust the configuration file if necessary:

```
config/config.json
```

3. Run the main script:

```powershell
.\Script.ps1
```

4. Enter the Active Directory group name when prompted.

---

## Output

Depending on configuration and selected options, the script generates:

* JSON backups of group hierarchies
* Flattened user evaluation reports
* Comparison result files
* Timestamped log files for full traceability

---

## Use Cases

* Active Directory access audits
* Documentation of complex group structures
* Preparation for AD migrations
* Cleanup and optimization of nested group memberships
* Portfolio demonstration of automation skills

---

## Skills Demonstrated

* Modular PowerShell scripting
* Active Directory automation
* Recursive data processing
* Logging and error handling
* Configuration-driven execution

---

## License

This project is licensed under the MIT License.
