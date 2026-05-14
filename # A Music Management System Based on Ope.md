# A Music Management System Based on OpenGauss Database

---


# Abstract
With the rapid development of online music services, the management of user information, music resources, and system permissions has become increasingly complex and critical. This database course design takes a music management system as the research object, completing the design and implementation based on the openGauss database with Python and Streamlit.

The system adopts a front-end and back-end separation architecture, establishing three independent roles: system administrator, music administrator, and ordinary listener, to realize hierarchical permission control. It covers core functions including user registration and login, music information management, user account management, and community interaction. Specifically, the system administrator module supports user list display, username search, role modification, and secure deletion, and includes a security mechanism to ensure at least one system administrator is retained, avoiding system management failure.

Through this project, our team has mastered the complete process of database design and application system development, including requirement analysis, E-R diagram design, relational schema conversion, and SQL statement writing. The system has passed basic tests and meets the basic functional requirements of the database course design, laying a solid foundation for further learning and practice of database technology.

**Keywords**: database; openGauss; music management system; permission control; user management

---

# 1 Project Background
In recent years, digital music services have developed rapidly and become one of the most important Internet applications. A large number of users, music resources, interactive data and management operations are involved in such systems, which brings high requirements for data storage, management efficiency and information security. Traditional file-based storage or simple data management methods can no longer meet the needs of stable operation, efficient query, concurrent access and secure management.

Database technology provides a standardized, safe and efficient way to organize and manage massive data. It has become the core support of modern information systems. Mastering database design, implementation and application is an important part of computer and data-related professional training.

Therefore, this course design takes a music management system as the practical theme. It aims to combine database theory with real application scenarios, so that we can consolidate professional knowledge, master the complete process of database system design and development, and improve the ability to solve practical data management problems through the whole process of requirement analysis, schema design, system implementation and testing.

---

# 2 Design Justification (Design Philosophy)
This system adopts the front-end and back-end separation architecture. The design follows the principles of function integrity, data security, permission independence, and easy maintenance.

The system meets the following requirements:
- Complete functions: realize user registration, login, query, update and deletion.
- Permission control: three roles are isolated from each other to avoid unauthorized access.
- Data integrity: use primary keys, foreign keys and constraints to ensure data consistency.
- Operating environment: based on Python + Streamlit + openGauss, with stable performance and friendly interface.
- Security: set necessary verification and anti-misoperation mechanisms.

---

# 3 Process Description
This section details the design and implementation process of the music management system, including requirement analysis, database design, system architecture, module implementation, and testing. The description is structured as follows：

## 3.1 Requirement Analysis
This music management system is designed to meet the functional and non-functional requirements of multi-role collaborative music resource management.

- **Functional Requirements**
  - User management: User registration, login, logout, personal information editing and account cancellation.
  - Permission control: RBAC-based access control, defining three roles: listener, music administrator, and system administrator.
  - Music management: CRUD operations for songs, artists and albums, with multi-field fuzzy search.
  - Playlist management: Create, edit and delete playlists, add/remove songs, and count total duration.
  - Interaction features: Song comments, likes, forum posts and replies.
  - Ranking display: Music rankings based on likes and comment counts.
  - Background management: User management, role assignment, password reset, and illegal content cleanup.

- **Non-Functional Requirements**
  - Security: User passwords are stored with PBKDF2-SHA256 hash encryption, with no plaintext retained.
  - Stability: Support concurrent operations with basic exception handling and error prompts.
  - Maintainability: Modular design with decoupled components for easy expansion.
  - Usability: Clear interface interaction, paging display, and session state synchronization.



## 3.2 Database Design
Design E-R diagram, convert it into relational mode, and create data tables including user table, music table, comment table and so on.

Based on the design principles outlined in Section 2, this section details the database implementation.


### 3.2.1 E-R Diagram Design

First, core entities and relationships are identified, including Users, Roles, Songs, Artists, Albums, Playlists, Comments, and Posts.

- **Before the diagram**: The ER diagram visually presents the system data model, serving as the basis for relational schema conversion.

- **After the diagram**: It clearly shows relationships: many-to-one between users and roles, many-to-one between songs and artists/albums, many-to-many between playlists and songs (via `Playlist_Songs`), and one-to-many between users and comments/posts.

### 3.2.2 Relational Schema Conversion

The ER model is converted into relational tables for openGauss. Core tables include:

- **Users**: Stores user info, including `user_id`, `username`, `password_hash`, `role`, `avatar_url`.

- **Artists**: Stores `artist_id` and `name`.

- **Albums**: Stores `album_id`, `title`, and `artist_id`.

- **Songs**: Stores `song_id`, `title`, `artist_id`, `album_id`, `duration_seconds`, `audio_url`.

- **Playlists**: Stores `playlist_id`, `name`, `creator_id`, `created_at`.

- **Playlist_Songs**: Intermediate table for playlists and `songs`.

- **Comments and Posts**: Stores song comments and forum posts.

### 3.2.3 SQL Implementation and Constraints

Tables are created with primary keys, foreign keys, and constraints. For example, the `Users` table:

```sql
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('sys_admin', 'music_admin', 'listener')),
    bio TEXT,
    avatar_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
Constraints: `CHECK` limits role values, `ON DELETE CASCADE` ensures associated comments and playlists are deleted automatically when users or songs are removed.

## 3.3 System Architecture and Environment Construction
Build a development environment based on Python and Streamlit, and complete the connection with openGauss database.

The system adopts a front-end and back-end separated architecture:

- **Back-end**: Python + openGauss, responsible for data processing, business logic and database interaction.

- **Front-end**: Streamlit, responsible for user interface display and interaction.

The environment setup steps are as follows:

1. Install Python 3.8+ and configure the openGauss database, creating the `music_system` database.

2. Install dependencies via pip: `streamlit`, `psycopg2`, `werkzeug`.

3. Implement database connection in `db_init.py` with exception handling.

4. Configure Streamlit page layout, including sidebar, tabs, paging controls, and session state management.

## 3.4 Module Implementation
Develop user login module, music management module, system administrator module and permission control module. The system administrator module supports user list display, username search, role modification and secure deletion.

The system is divided into several independent functional modules:

### 3.4.1 User Authentication and Permission Control

Implemented in `auth.py`, it handles login, registration, logout and permission verification:

- Passwords are verified via `check_password_hash` to ensure security.
- The `@auth.require_role()` decorator intercepts unauthorized access. For example, `add_song` is restricted to `sys_admin` and `music_admin`.

### 3.4.2 Music Management

Implemented by the `MusicManager` class:

- **Add songs**: Automatically creates new artists/albums if they don't exist.
- **Update songs**: Uses `COALESCE` to update only specified fields.
- **Delete songs**: Executes `DELETE` with cascade rules.
- **Fuzzy search**: Uses `ILIKE` to match song titles, artist names, and album titles.

### 3.4.3 Playlist Management

- Users can create, edit and delete their own playlists, and add/remove songs.
- Admins can view and delete any playlists on the platform.
- The "My Favorite Songs" playlist is automatically managed when users like/unlike songs.

### 3.4.4 Interaction and Forum

- Song comments: Users can publish/delete their own comments; admins can delete any comments.
- Forum posts: Users can publish and reply to posts, with support for recommended songs.
- Rankings: Aggregate queries count likes and comments to generate paginated rankings.

### 3.4.5 System Administrator Module

Exclusive to `sys_admin`:

- View all users, search by username, and filter by role.
- Modify user roles, reset passwords, and delete illegal users (with a safety check to prevent deleting the last admin).

## 3.5 System Test and Optimization
Test the functions of adding, deleting, modifying, querying and permission control to ensure the stability and correctness of the system.

Comprehensive testing and optimization were performed:

1. **Functional testing**: Verified core functions including login, permission control, music management, and playlist operations.

2. **Exception handling**: Tested scenarios such as database connection failures, invalid parameters, and insufficient permissions, improving error prompts and transaction rollbacks.

3. **Performance optimization**: Optimized SQL queries and added pagination to improve response times with large datasets.

4. **UI optimization**: Adjusted Streamlit layouts and interactions to enhance user experience.

---

# 4 Results Analysis
After comprehensive testing, this music library management system has successfully implemented all core functions required by the course design. The overall operation is stable, and the performance of each module meets the expected goals.

1. **Verification of User and Permission Management Functions**

   - User registration, login, and logout processes run normally. Passwords are stored with PBKDF2-SHA256 hash encryption, and login verification uses one-way comparison, eliminating the risk of plain-text password leakage throughout the process.
   - The RBAC permission control mechanism is effective, with clear isolation of permissions for the three roles: ordinary users cannot access the music library management and user management backend, music administrators cannot operate user role assignments, and system administrators have full permissions. Unauthorized access attempts are successfully intercepted.

2. **Verification of Music and Playlist Management Functions**

   - CRUD operations for songs, automatic creation of artists/albums, and multi-field fuzzy search functions work normally, supporting case-insensitive matching of song titles, artist names, and album titles with stable query efficiency.
   - Playlist management functions are complete: users can create, edit, and delete personal playlists, add/remove songs normally, and aggregate statistics of playlist total duration are accurate. Administrators can view and manage all platform playlists, cascade deletion rules take effect, and associated playlist data is automatically updated after songs are deleted.

3. **Verification of Interactive and Forum Functions**

   - Song comments, likes, forum post publishing and replying functions run normally. Comment/post deletion permissions are controlled effectively (users can only delete their own content, and administrators can delete any illegal content).
   - The ranking function works normally, with accurate results from aggregate queries based on likes and comment counts, clear paging display logic, and stable data loading.

4. **Verification of System Stability and Security**

   - The system can handle concurrent operations. Scenarios such as database connection failures, invalid parameters, and insufficient permissions all have friendly error prompts and transaction rollback mechanisms, with no data loss or program crashes.
   - The security check when the system administrator deletes a user is effective, prohibiting the deletion of the last system administrator, effectively avoiding platform management failure.

In summary, the system has met the functional and performance requirements of the course design and achieved the design goal of multi-role collaborative music management.


---

# 5 Course Design Summary
In this course design, we developed a music library management system and completed the entire process including requirement analysis, database design, function implementation, system testing and optimization. Through practical development, we not only applied database knowledge learned in class to a real system, but also deeply understood the importance of system security, permission control and module design in the process of debugging and improvement.

In the early stage of development, the most significant problem we encountered was imperfect permission allocation. The initial permission logic was too simple: ordinary users and music administrators could be promoted to system administrators, which brought obvious risks of permission abuse and violated the design purpose of RBAC permission isolation. After realizing this problem, we reorganized the permission boundaries of the three roles, strictly restricted the role modification authority, ensured that only system administrators can assign roles, and prohibited low-privilege roles from unauthorized promotion. Finally, we built a safer and more standardized permission system.

Secondly, in the user management module, we found that the user deletion function had serious security risks. The original design did not limit the number of system administrators. If the last system administrator was deleted, the entire platform would lose the highest authority manager, making the system unmanageable. To solve this problem, we added a verification logic for the number of administrators. When there was only one system administrator left in the system, the deletion operation was prohibited. This mechanism avoided management failure and made us realize the necessity of security verification in background management.

In addition, the initial design of the forum module was not perfect. The function structure was simple, the interaction logic was unclear, and the association, display and deletion permissions of posts and comments were unreasonable. In the testing stage, we gradually optimized the interaction process of the forum, improved the functions of posting, replying and content deletion, and clarified the operation permissions of users and administrators. This process made us understand that module design should not only meet basic functions, but also fit actual usage scenarios.

This project also brought us a lot in team collaboration. We divided the work of database construction, function development, interface debugging and testing, discussed and assisted each other when encountering problems. It not only improved development efficiency, but also exercised our communication and problem-solving abilities. From being unfamiliar with frameworks and databases at the beginning to finally completing a stable system with complete functions and clear permissions, our practical ability and engineering thinking have been significantly improved.

Through this course design, we realized that database design, permission control and security verification are critical to the stable operation of the system. Any carelessness in details may lead to functional abnormalities or security risks. In the future, we will pay more attention to the rigor and integrity of the system, apply the experience accumulated in this practice to subsequent learning and development, and continuously improve our professional abilities.