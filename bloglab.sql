create table ApplicationUser(
    ApplicationUserId INT NOT NULL IDENTITY(1,1),
    Username varchar(20) NOT NULL,
    NormalizedUsername varchar(20) not null,
    Email varchar(30) NOT null,
    NormalizedEmail varchar(30) not null,
    Fullname varchar(30) null,
    PasswordHash NVARCHAR(max) not NULL
    Primary key (ApplicationUserId)
)

create Index [IX_ApplicationUser_NormalizedUsername] on [sametirk_cv].[ApplicationUser] ([NormalizedUsername])
create Index [IX_ApplicationUser_NormalizedEmail] on [sametirk_cv].[ApplicationUser] ([NormalizedEmail])


select * from ApplicationUser


create table Photo(
    PhotoId INT NOT NULL IDENTITY(1,1),
    ApplicationUserId INT NOT NULL,
    PublicId varchar(50) NOT NULL,
    ImageURL varchar(250) NOT NULL , 
    [Description] varchar(30) NOT NULL,
    PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
    UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (PhotoId),
    FOREIGN KEY (ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId)
)


create table Blog(
    BlogId  INT NOT NULL IDENTITY(1,1),
    ApplicationUserId INT NOT NULL,
    PhotoId INT Null,
    Title varchar(50) NOT NULL,
    Content varchar(max) NOT NULL,
    PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
    UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
    ActiveInd BIT NOT NULL DEFAULT CONVERT(BIT,1)
    PRIMARY KEY (BlogId)
    FOREIGN KEY (PhotoId) REFERENCES Photo(PhotoId),
    FOREIGN KEY (ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId)
)

create table BlogComment(
    BlogCommentId  INT NOT NULL IDENTITY(1,1),
    ParentBlogCommentId INT NULL , 
    BlogId INT NOT NULL,
    ApplicationUserId INT NOT NULL , 
    Content varchar(300) NOT NULL , 
    PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
    UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
    ActiveInd BIT NOT NULL DEFAULT CONVERT(BIT,1),
    PRIMARY KEY (BlogCommentId),
    FOREIGN KEY (BlogId) REFERENCES Blog(BlogId),
    FOREIGN KEY (ApplicationUserId) REFERENCES  ApplicationUser(ApplicationUserId)
)

create SCHEMA [aggregate]


create VIEW [aggregate].[BlogComment]
AS
    SELECT 
        t1.BlogCommentId,
        t1.ParentBlogCommentId,
        t1.BlogId,
        t1.Content,
        t2.Username,
        t1.ApplicationUserId,
        t1.PublishDate,
        t1.UpdateDate,
        t1.ActiveInd
    FROM
        sametirk_cv.BlogComment t1 
    Inner JOIN
        sametirk_cv.ApplicationUser t2 ON t1.ApplicationUserId = t2.ApplicationUserId




CREATE TYPE [sametirk_cv].[BlogType] As TABLE

(
  
    [BlogId] INT NOT NULL,
    [Title] varchar(250) not null,
    [Content] varchar(MAX) NOT null,
    [PhotoId] INT NOT null
  
)

CREATE TYPE [sametirk_cv].[PhotoType] As TABLE

(
  
    [PublicId] varchar(50) NOT NULL,
    [ImageURL] varchar(250) not null,
    [Description] varchar(30) NOT null
  
)

CREATE TYPE [sametirk_cv].[AccountType] As TABLE

(
  
    [Username] varchar(20) NOT NULL,
    [NormalizedUsername] varchar(20) not null,
    [Email] varchar(30) NOT null,
    [NormalizedEmail] varchar(30) not null,
    [Fullname] varchar(30) null,
    [PasswordHash] NVARCHAR(max) not NULL
)

CREATE TYPE [sametirk_cv].[BlogCommentType] As TABLE
(
    [BlogCommentId] INT NOT NULL,
    [ParentBlogCommentId] INT NULL,
    [BlogId] INT NOT NULL,
    [Content] VARCHAR(300) NOT NULL
)



create PROC [sametirk_cv].[Account_GetByUserName]
    @NormalizedUsername VARCHAR(20)


    AS 

    Select 
            [ApplicationUserId],
            [Username] ,
            [NormalizedUsername],
            [Email],
            [NormalizedEmail], 
            [Fullname] ,
            [PasswordHash]
    From 
        [sametirk_cv].[ApplicationUser] t1
    WHERE
        t1.[NormalizedUsername] = @NormalizedUsername


create procedure [sametirk_cv].[Account_Insert]
    @Account AccountType READONLY
AS 
    Insert INTO 
        [sametirk_cv].[ApplicationUser]
            ( [Username] ,
            [NormalizedUsername],
            [Email],
            [NormalizedEmail], 
            [Fullname] ,
            [PasswordHash])
    SELECT 
         [Username] ,
         [NormalizedUsername],
         [Email],
         [NormalizedEmail], 
         [Fullname] ,
         [PasswordHash]
    FROM 
        @Account
    
    SELECT CAST(SCOPE_IDENTITY() as INT);


create PROCEDURE [sametirk_cv].[Blog_Delete]

    @BlogId INT
AS
    UPDATE [sametirk_cv].[BlogComment]
    set [ActiveInd] = CONVERT(Bit ,0)
    where [BlogId] = @BlogId;

    UPDATE [sametirk_cv].[Blog]
    SET 
        [PhotoId] = NULL,
        [ActiveInd] = CONVERT(BIT , 0 )
    WHERE 
        [BlogId] = @BlogId



create procedure [sametirk_cv].[Blog_Get]

    @BlogId INT
AS
    SELECT 
            [BlogId],
            [ApplicationUserId],
            [Username] ,
            [Title],
            [Content],
            [PhotoId], 
            [PublishDate] ,
            [UpdateDate],
            [ActiveInd]
    FROM
        [aggregate].[Blog] t1
    WHERE 
        t1.[BlogId] = @BlogId AND 
        t1.ActiveInd = CONVERT(BIT,1)



create PROCEDURE [sametirk_cv].[Blog.GetAll]
    @OffSet INT,
    @PageSize INT

AS

    SELECT 
            [BlogId],
            [ApplicationUserId],
            [Username] ,
            [Title],
            [Content],
            [PhotoId], 
            [PublishDate] ,
            [UpdateDate],
            [ActiveInd]
    FROM
        [aggregate].[Blog] t1
    Where 
        t1.[ActiveInd] = CONVERT(BIT,1)
    ORDER BY 
        t1.[BlogId]
    OFFSET @Offset ROWS 
    FETCH NEXT @PageSize ROWS ONLY;

    SELECT COUNT(*) FROM [aggregate].[Blog] t1 where t1.[ActiveInd] = CONVERT(BIT,1);


ALTER PROCEDURE [sametirk_cv].[Blog_GetAllFamous]

AS 
    SELECT  
    TOP 6
            t1.[BlogId],
            t1.[ApplicationUserId],
            t1.[Username],
            t1.[PhotoId], 
            t1.[Title],
            t1.[Content],
            t1.[PublishDate] ,
            t1.[UpdateDate],
            t1.[ActiveInd]
    FROM 
        [aggregate].[Blog] t1 
    INNER JOIN
        [sametirk_cv].[BlogComment] t2 on t1.BlogId = t2.BlogId
    WHERE 
        t1.ActiveInd = CONVERT(BIT , 1) AND t2.ActiveInd = CONVERT(BIT,1)
    GROUP BY
            t1.[BlogId],
            t1.[ApplicationUserId],
            t1.[Username],
            t1.[PhotoId], 
            t1.[Title],
            t1.[Content],
            t1.[PublishDate] ,
            t1.[UpdateDate],
            t1.[ActiveInd]
    Order BY 
        COUNT (t2.BlogCommentId)
    DESC
        

CREATE PROCEDURE [sametirk_cv].[Blog_GetByUserId]
    @ApplicationUserId INT
AS

    SELECT 
            [BlogId],
            [ApplicationUserId],
            [Username] ,
            [Title],
            [Content],
            [PhotoId], 
            [PublishDate] ,
            [UpdateDate],
            [ActiveInd]
    FROM
        [aggregate].[Blog] t1 
    WHERE
        t1.[ApplicationUserId] = @ApplicationUserId AND
        t1.[ActiveInd] = CONVERT(BIT,1)



ALTER PROCEDURE [sametirk_cv].[Blog_Upsert]
    @Blog BlogType READONLY,
    @ApplicationUserId INT
as
    MERGE INTO [sametirk_cv].[Blog] TARGET
    USING 
        (
            SELECT
                BlogId,
                @ApplicationUserId [ApplicationUserId],
                Title,
                Content,
                PhotoId
            From 
                @Blog
        ) AS SOURCE
        ON
        (
            TARGET.BlogId = SOURCE.BlogId AND TARGET.ApplicationUserId = SOURCE.ApplicationUserId
        )

        WHEN MATCHED THEN 
            UPDATE SET 
                TARGET.[Title] = SOURCE.[Title],
                TARGET.[Content] = SOURCE.[Content],
                TARGET.[PhotoId] = SOURCE.[PhotoId],
                TARGET.[UpdateDate] = GETDATE()
        WHEN NOT MATCHED  BY TARGET THEN
            INSERT (
                [ApplicationUserId],
                [Title],
                [Content],
                [PhotoId]
            )
            VALUES(
                SOURCE.[ApplicationUserId],
                SOURCE.[Title],
                SOURCE.[Content],
                SOURCE.[PhotoId]
            );

    SELECT CAST(SCOPE_IDENTITY() AS INT);




alter PROCEDURE [sametirk_cv].[BlogComment_Delete]
    @BlogCommentId INT
AS
    DROP TABLE IF EXISTS #BlogCommentsToBeDelete;

    WITH cte_blogComments AS(

        SELECT 
            t1.[BlogCommentId],
            t1.[ParentBlogCommentId]
        FROM 
            [sametirk_cv].[BlogComment] t1 
        WHERE 
            t1.[BlogCommentId] = @BlogCommentId
        UNION ALL

        SELECT 
            t2.[BlogCommentId],
            t2.[ParentBlogCommentId]
        FROM
            [sametirk_cv].BlogComment t2
            INNER JOIN cte_blogComments t3
                ON t3.[BlogCommentId] = t2.[ParentBlogCommentId]
        )

        SELECT 
            [BlogCommentId],
            [ParentBlogCommentId]
        INTO
            #BlogCommentsToBeDelete
        FROM
            cte_blogComments;
        UPDATE t1

        SET 
            t1.[ActiveInd] = CONVERT(BIT,0),
            t1.[UpdateDate] = GETDATE()
        FROM
            [sametirk_cv].[BlogComment] t1
            INNER JOIN #BlogCommentsToBeDelete t2
                ON t1.[BlogCommentId] = t2.[BlogCommentId];
GO


CREATE PROCEDURE [sametirk_cv].[Blogcomment_Get]
    @BlogCommentId INT

AS

    SELECT
            t1.[BlogCommentId],
            t1.[ParentBlogCommentId],
            t1.[BlogId] ,
            t1.[ApplicationUserId],
            t1.[Username],
            t1.[Content],
            t1.[PublishDate] ,
            t1.[UpdateDate],
            t1.[ActiveInd]
    FROM
        [aggregate].[BlogComment] t1

    WHERE 
        t1.[BlogCommentId] = @BlogCommentId AND
        t1.[ActiveInd] = CONVERT(BIT,1)


CREATE PROCEDURE [sametirk_cv].[BlogComment_GetAll]
    @BlogId INT
AS
     SELECT
            t1.[BlogCommentId],
            t1.[ParentBlogCommentId],
            t1.[BlogId] ,
            t1.[ApplicationUserId],
            t1.[Username],
            t1.[Content],
            t1.[PublishDate] ,
            t1.[UpdateDate],
            t1.[ActiveInd]
    FROM
        [aggregate].[BlogComment] t1

    WHERE 
        t1.[BlogId] = @BlogId AND
        t1.[ActiveInd] = CONVERT(BIT,1)
    
    ORDER BY 
        t1.[UpdateDate]
    DESC




CREATE PROCEDURE [sametirk_cv].[BlogComment_Upsert]
    @BlogComment BlogCommentType READONLY,
    @ApplicationUserId INT
AS

    MERGE INTO [sametirk_cv].[BlogComment] TARGET
    USING
    (
        SELECT
            [BlogCommentId],
            [ParentBlogCommentId],
            [BlogId],
            [Content],
            @ApplicationUserId [ApplicationUserId]
        FROM
        @BlogComment
    ) AS SOURCE
    ON
    (
        TARGET.[BlogCommentId] = SOURCE.[BlogCommentId] AND TARGET.[ApplicationUserId] = SOURCE.[ApplicationUserId]
    )
    WHEN MATCHED THEN
        UPDATE SET  
            TARGET.[Content] = SOURCE.[Content],
            TARGET.[UpdateDate] = GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            [ParentBlogCommentId],
            [BlogId],
            [ApplicationUserId],
            [Content]
        )
        VALUES
        (
            SOURCE.[ParentBlogCommentId],
            SOURCE.[BlogId],
            SOURCE.[ApplicationUserId],
            SOURCE.[Content]
        );
        SELECT CAST(SCOPE_IDENTITY() AS INT);


CREATE PROCEDURE [sametirk_cv].[Photo_Delete]
    @PhotoId INT

AS
    delete from [sametirk_cv].[Photo] WHERE [PhotoId] = @PhotoId

CREATE PROCEDURE [sametirk_cv].[Photo_Get]
    @PhotoId INT

AS
    SELECT 
        t1.[PhotoId],
        t1.[ApplicationUserId],
        t1.[PublicId],
        t1.[ImageURL],
        t1.[Description],
        t1.[PublishDate],
        t1.[UpdateDate]
    FROM
        [sametirk_cv].[Photo] t1
    WHERE
        t1.[PhotoId] = @PhotoId




CREATE PROCEDURE [sametirk_cv].[Photo_GetByUserId]
    @ApplicationUserId INT

AS
    SELECT 
        t1.[PhotoId],
        t1.[ApplicationUserId],
        t1.[PublicId],
        t1.[ImageURL],
        t1.[Description],
        t1.[PublishDate],
        t1.[UpdateDate]
    FROM
        [sametirk_cv].[Photo] t1
    WHERE
        t1.[ApplicationUserId] = @ApplicationUserId


CREATE PROCEDURE [sametirk_cv].[Photo_INSERT]
    @Photo PhotoType READONLY,
    @ApplicationUserId INT

AS
    INSERT INTO [sametirk_cv].[Photo]  
     
        ([ApplicationUserId],
        [PublicId],
        [ImageURL],
        [Description])
    SELECT
        @ApplicationUserId,
        [PublicId],
        [ImageURL],
        [Description]
    FROM
       @Photo;

    SELECT CAST(SCOPE_IDENTITY() AS INT);

GO

