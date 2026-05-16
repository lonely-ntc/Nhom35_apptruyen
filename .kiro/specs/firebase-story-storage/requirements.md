# Requirements Document

## Introduction

This document specifies the requirements for migrating story content storage from SQLite to Firebase Firestore in the Flutter story reading application. Currently, story metadata and content (chapters) are stored in a local SQLite database, while story cover images are stored on Cloudinary. The migration will move story metadata and chapter content to Firebase Firestore while maintaining Cloudinary for image storage.

## Glossary

- **Story_Service**: The service layer responsible for managing story data operations
- **Database_Service**: The existing SQLite database service that will be refactored
- **Firestore_Service**: The Firebase Firestore service for cloud storage operations
- **Story_Metadata**: Story information including title, author, category, status, description, price, and is_free flag
- **Chapter_Content**: Individual chapter data including chapter name, content text, and link
- **Admin_Interface**: The administrative screens for adding and managing stories
- **SQLite_Database**: The local database currently storing story and chapter data
- **Cloudinary**: The cloud service for storing and serving story cover images
- **Migration_Tool**: A utility for transferring existing data from SQLite to Firestore

## Requirements

### Requirement 1: Store Story Metadata in Firestore

**User Story:** As an administrator, I want story metadata to be stored in Firebase Firestore, so that story information is accessible across all devices and platforms.

#### Acceptance Criteria

1. WHEN a new story is added, THE Story_Service SHALL store the Story_Metadata in Firestore collection "stories"
2. THE Story_Service SHALL store the following fields in Firestore: title, author, category, status, totalChapters, description, imagePath, isFree, price, createdAt, updatedAt
3. THE Story_Service SHALL use the story title as the document ID in the "stories" collection
4. WHEN Story_Metadata is stored, THE Story_Service SHALL sanitize the title by trimming whitespace and normalizing spaces
5. THE Story_Service SHALL validate that required fields (title, author, category) are not empty before storing

### Requirement 2: Store Chapter Content in Firestore

**User Story:** As an administrator, I want chapter content to be stored in Firebase Firestore, so that chapters are available in the cloud and can be accessed from any device.

#### Acceptance Criteria

1. WHEN a chapter is added to a story, THE Story_Service SHALL store the Chapter_Content in a subcollection "chapters" under the story document
2. THE Story_Service SHALL store the following fields for each chapter: chapterName, content, link, chapterNumber, createdAt
3. THE Story_Service SHALL use the chapter link as the document ID in the "chapters" subcollection
4. WHEN chapters are retrieved, THE Story_Service SHALL return them sorted by chapterNumber in ascending order
5. THE Story_Service SHALL support storing chapter content up to 1MB per chapter document

### Requirement 3: Maintain Cloudinary for Image Storage

**User Story:** As an administrator, I want story cover images to remain on Cloudinary, so that image hosting and delivery continues to work efficiently.

#### Acceptance Criteria

1. WHEN a story is added, THE Admin_Interface SHALL upload the cover image to Cloudinary before storing Story_Metadata
2. THE Story_Service SHALL store the Cloudinary URL in the imagePath field of Story_Metadata
3. WHEN a story image is updated, THE Admin_Interface SHALL upload the new image to Cloudinary and update the imagePath in Firestore
4. THE Story_Service SHALL not store image binary data in Firestore
5. WHEN retrieving stories, THE Story_Service SHALL return the Cloudinary URL for image display

### Requirement 4: Update Story Operations

**User Story:** As an administrator, I want to update existing stories in Firestore, so that I can modify story information after creation.

#### Acceptance Criteria

1. WHEN a story is updated, THE Story_Service SHALL update the Story_Metadata in the Firestore "stories" collection
2. WHEN the story title is changed, THE Story_Service SHALL create a new document with the new title and delete the old document
3. WHEN the story title is changed, THE Story_Service SHALL migrate all chapters to the new story document
4. THE Story_Service SHALL update the updatedAt timestamp whenever Story_Metadata is modified
5. WHEN updating fails, THE Story_Service SHALL return an error without modifying the existing data

### Requirement 5: Delete Story Operations

**User Story:** As an administrator, I want to delete stories from Firestore, so that I can remove unwanted content completely.

#### Acceptance Criteria

1. WHEN a story is deleted, THE Story_Service SHALL delete the story document from the "stories" collection
2. WHEN a story is deleted, THE Story_Service SHALL delete all documents in the "chapters" subcollection
3. WHEN a story is deleted, THE Story_Service SHALL delete the story from all user wishlists and following lists
4. WHEN a story is deleted, THE Story_Service SHALL delete all ratings and comments associated with the story
5. THE Story_Service SHALL not delete the Cloudinary image when a story is deleted

### Requirement 6: Retrieve Stories from Firestore

**User Story:** As a user, I want to view stories stored in Firestore, so that I can browse and read available content.

#### Acceptance Criteria

1. WHEN stories are requested, THE Story_Service SHALL retrieve Story_Metadata from the Firestore "stories" collection
2. THE Story_Service SHALL return stories sorted by title in ascending order by default
3. THE Story_Service SHALL support filtering stories by category
4. THE Story_Service SHALL support searching stories by title, author, or category keywords
5. WHEN retrieving stories, THE Story_Service SHALL return results within 2 seconds for up to 1000 stories

### Requirement 7: Retrieve Chapters from Firestore

**User Story:** As a user, I want to read story chapters stored in Firestore, so that I can access chapter content from any device.

#### Acceptance Criteria

1. WHEN chapters are requested for a story, THE Story_Service SHALL retrieve Chapter_Content from the "chapters" subcollection
2. THE Story_Service SHALL return chapters sorted by chapterNumber in ascending order
3. WHEN a specific chapter is requested by link, THE Story_Service SHALL retrieve the chapter document using the link as document ID
4. THE Story_Service SHALL return chapter content within 1 second for individual chapter requests
5. WHEN a story has no chapters, THE Story_Service SHALL return an empty list

### Requirement 8: Migrate Existing Data

**User Story:** As an administrator, I want to migrate existing story data from SQLite to Firestore, so that all current content is available in the new storage system.

#### Acceptance Criteria

1. THE Migration_Tool SHALL read all Story_Metadata from the SQLite_Database "truyen" table
2. THE Migration_Tool SHALL read all Chapter_Content from the SQLite_Database "chuong" table
3. THE Migration_Tool SHALL write Story_Metadata to Firestore "stories" collection preserving all fields
4. THE Migration_Tool SHALL write Chapter_Content to Firestore "chapters" subcollections under the corresponding story documents
5. THE Migration_Tool SHALL log the migration progress and report any errors without stopping the migration process
6. THE Migration_Tool SHALL verify that the number of stories and chapters in Firestore matches SQLite after migration
7. WHEN migration is complete, THE Migration_Tool SHALL generate a summary report showing total stories migrated, total chapters migrated, and any errors encountered

### Requirement 9: Maintain Backward Compatibility During Migration

**User Story:** As a developer, I want the application to support both SQLite and Firestore during migration, so that the transition can be gradual and reversible.

#### Acceptance Criteria

1. THE Database_Service SHALL support a configuration flag to enable Firestore mode or SQLite mode
2. WHEN Firestore mode is enabled, THE Database_Service SHALL read and write data to Firestore
3. WHEN SQLite mode is enabled, THE Database_Service SHALL read and write data to SQLite
4. THE Database_Service SHALL provide the same interface for both storage modes
5. WHEN switching between modes, THE Database_Service SHALL not require changes to the Admin_Interface or user-facing screens

### Requirement 10: Handle Firestore Errors

**User Story:** As a user, I want the application to handle Firestore errors gracefully, so that I receive clear feedback when operations fail.

#### Acceptance Criteria

1. WHEN a Firestore write operation fails, THE Story_Service SHALL return an error message describing the failure
2. WHEN a Firestore read operation fails, THE Story_Service SHALL return an empty result and log the error
3. WHEN network connectivity is lost, THE Story_Service SHALL return an error indicating no internet connection
4. WHEN Firestore quota is exceeded, THE Story_Service SHALL return an error indicating the service is temporarily unavailable
5. THE Story_Service SHALL not crash the application when Firestore operations fail

### Requirement 11: Optimize Firestore Queries

**User Story:** As a developer, I want Firestore queries to be optimized, so that data retrieval is fast and cost-effective.

#### Acceptance Criteria

1. THE Story_Service SHALL use Firestore indexes for queries that filter by category or search by keywords
2. THE Story_Service SHALL limit query results to 50 stories per request by default
3. THE Story_Service SHALL support pagination for retrieving additional stories beyond the initial limit
4. THE Story_Service SHALL cache story lists in memory for 5 minutes to reduce redundant Firestore reads
5. WHEN cache is valid, THE Story_Service SHALL return cached data without querying Firestore

### Requirement 12: Maintain Data Consistency

**User Story:** As an administrator, I want data consistency between Firestore and the application, so that all users see the same information.

#### Acceptance Criteria

1. WHEN Story_Metadata is updated, THE Story_Service SHALL use Firestore transactions to ensure atomic updates
2. WHEN a story title is changed, THE Story_Service SHALL use a batch write to update the story document and all related data atomically
3. WHEN multiple administrators edit the same story, THE Story_Service SHALL use Firestore's last-write-wins conflict resolution
4. THE Story_Service SHALL validate data integrity before writing to Firestore
5. WHEN a write operation fails partially, THE Story_Service SHALL rollback all changes to maintain consistency
