--1.  SP “Factorial”. SP verilən rəqəmin faktorialını hesablayır. 
--(mənfi ədədin faktorialı olmur, nəzərə alın)

CREATE PROCEDURE sp_Factorial
@number int,@result int OUTPUT
AS 
BEGIN
   IF @number>0
   BEGIN 
   WHILE @number!=0
   BEGIN
   SET @result=@result *@number
   SET @number=@number-1
   END
   END
END

DECLARE @result_ int=1;
DECLARE @number_ int=3;

EXECUTE sp_Factorial @number_,@result_ OUTPUT
PRINT @result_

--2. SP “Lazy Students”. SP heç vaxt kitab götürməyən tələbələri göstərir və output parametrlə bu tələbələrin sayını qaytarır

ALTER PROCEDURE sp_LazyStudents
@countStuds AS int OUTPUT
AS
BEGIN
    SET NOCOUNT ON
	SELECT FirstName, LastName
	FROM S_Cards FULL JOIN Students 
	ON S_Cards.Id_Student = Students.Id  
	WHERE S_Cards.Id_Lib IS NULL

	SET @countStuds = @@ROWCOUNT
END

DECLARE @size int=0;
EXEC sp_LazyStudents @size out
PRINT @size

--3. SP "Books on the criteria". SP verilən kriteriyalara uyğun olan kitabların listini göstərir : author name, surname , subject, category. 
--Əlavə olaraq list verilən 5-ci parametrə görə sort olunmalıdır, 6cı parametrdə isə hansı istiqamətdə sort olunacağı qeyd olunur.
-- 5ci parametr üçün göndərilə biləcək rəqəmlər (sütunlar) : 1) book identifier, 2) book title, 3) surname and name of the author, 4) topic, 5) category.

CREATE PROCEDURE sp_BooksOnTheCriteria
  @Criteria int,@1Asc0Desc int
AS
BEGIN
  SELECT Authors.FirstName,Authors.LastName,Themes.Name AS ThemesName,Categories.Name AS CategoryName
  FROM Authors INNER JOIN Books
  ON Authors.Id=Books.Id_Author INNER JOIN Categories
  ON Books.Id_Category=Categories.Id INNER JOIN Themes
  ON Books.Id_Themes=Themes.Id
  ORDER BY

  --1.Books Id
  CASE
     WHEN @Criteria=2 AND @1Asc0Desc=1 THEN Books.Id 
  END ASC,
  CASE
     WHEN @Criteria=2 AND @1Asc0Desc=0 THEN Books.Id 
  END DESC,
  --2.Books Name
  CASE
     WHEN @Criteria=2 AND @1Asc0Desc=1 THEN Books.Name 
  END ASC,
  CASE
     WHEN @Criteria=2 AND @1Asc0Desc=0 THEN Books.Name  
  END DESC,
  --3.Surname and Name Author
  CASE
     WHEN @Criteria=3 AND @1Asc0Desc=1 THEN Authors.FirstName+' '+Authors.LastName 
  END ASC,
  CASE
     WHEN @Criteria=3 AND @1Asc0Desc=0 THEN Authors.FirstName+' '+Authors.LastName 
  END DESC,
  --4.Themes Name
   CASE
     WHEN @Criteria=4 AND @1Asc0Desc=1 THEN Themes.Name
  END ASC,
  CASE
     WHEN @Criteria=4 AND @1Asc0Desc=0 THEN Themes.Name
  END DESC,
  --Category Name
  CASE
     WHEN @Criteria=5 AND @1Asc0Desc=1 THEN Categories.Name
  END ASC,
  CASE
     WHEN @Criteria=5 AND @1Asc0Desc=0 THEN Categories.Name
  END DESC
END

EXECUTE sp_BooksOnTheCriteria 5,1

--4. SP "Adding a student". SP tələbə və grup əlavə edir. 
--Əgər eyni adlı qrup varsa, bu halda Tələbənin İd_Group sütununa həmin köhnə qrupun İd-si yazılır. 
--Əgər qrup adı yoxdursa onda ilkin olaraq grup daha sonra tələbə əlavə olunur.
--Əlavə olaraq nəzərə alın ki grup adları UPPERCASE ilə verilənlər bazasında saxlanılır, 
--amma heç kim zəmanət vermir ki, Procedure çağıran şəxs onu UPPERCASE göndərəcək

ALTER PROCEDURE sp_AddingStudent
@GroupId int,@Groupname NVARCHAR(10),@Id_Faculty int,@StudentId int,@FirstName NVARCHAR(15),@LastName NVARCHAR(25),@Term int,@Id_Group int
AS 
BEGIN

   IF EXISTS(SELECT Groups.Name FROM Groups WHERE Groups.Name=UPPER(@Groupname))
   BEGIN

   SET @Id_Group=(SELECT Groups.Id FROM Groups WHERE Groups.Name=UPPER(@Groupname))
   INSERT INTO Students(Id,FirstName,LastName,Id_Group,Term)
   VALUES(@StudentId,@FirstName,@LastName,@Id_Group,@Term)

   END

   ELSE
   BEGIN

   INSERT INTO Groups(Id,Name,Id_Faculty)
   VALUES(@GroupId,UPPER(@Groupname),@Id_Faculty)
 
   INSERT INTO Students(Id,FirstName,LastName,Id_Group,Term)
   VALUES(@StudentId,@FirstName,@LastName,@Id_Group,@Term)

   END

  
END

--5. SP "Purchase of popular books". SP tələbələr və müəlimlər arasında (eyni zamanda) məşhur olan 5 kitabı tapır,
--və o kitabların hər birindən 3 ədəd alır.

CREATE PROCEDURE sp_PopularBooks
AS
BEGIN

    SELECT DISTINCT TOP 5 Books.[Name], Books.Quantity
	FROM Books INNER JOIN S_Cards ON S_Cards.Id_Book = Books.Id
	INNER JOIN T_Cards ON T_Cards.Id_Book = Books.Id

	IF EXISTS(SELECT TOP 5 Books.Quantity
	FROM Books INNER JOIN S_Cards 
	ON S_Cards.Id_Book = Books.Id INNER JOIN T_Cards 
	ON T_Cards.Id_Book = Books.Id
	WHERE Quantity >= 3)
	UPDATE Books
	SET Quantity -= 3
	FROM Books INNER JOIN S_Cards 
	ON S_Cards.Id_Book = Books.Id INNER JOIN T_Cards 
	ON T_Cards.Id_Book = Books.Id
	ELSE PRINT 'Bu kitablardan istenilan sayda yoxdur.'

END

--6. SP "Getting rid of unpopular books". SP 5 popular olmayan kitabları seçir və onların yarısını başqa təhsil müəsisəsinə verir.

CREATE PROCEDURE sp_RidUnPopularBooks
AS
BEGIN
SELECT DISTINCT TOP 5 Books.[Name], Books.Quantity
	FROM Books LEFT JOIN S_Cards ON S_Cards.Id_Book = Books.Id
	LEFT JOIN T_Cards ON T_Cards.Id_Book = Books.Id
	WHERE S_Cards.Id IS NULL AND T_Cards.Id IS NULL

	IF EXISTS(SELECT DISTINCT TOP 5 Books.[Name], Books.Quantity
	FROM Books LEFT JOIN S_Cards ON S_Cards.Id_Book = Books.Id
	LEFT JOIN T_Cards ON T_Cards.Id_Book = Books.Id
	WHERE S_Cards.Id IS NULL AND T_Cards.Id IS NULL AND Quantity % 2 = 0)
	UPDATE Books
	SET Quantity -= (Quantity / 2)
	FROM Books LEFT JOIN S_Cards ON S_Cards.Id_Book = Books.Id
	LEFT JOIN T_Cards ON T_Cards.Id_Book = Books.Id
	WHERE S_Cards.Id IS NULL AND T_Cards.Id IS NULL
END

EXEC sp_RidUnPopularBooks

--7. SP "A student takes a book." SP gets Id of a student and Id of a book. Check quantity of books in table Books (if quantity > 0). Check how many books student has now. If 3-4 books, then we issue a warning, and if there are already 5 books, then we do not give him a new book. If student can take this book, then add row in table S_Cards and update column quantity in table Books.
-- parametr std id ve book id.
-- Kitabin quanttiy si 0dan boyuk olmalidir
-- stdnin nece kitabi oldugunu yoxlayin
-- Əgər 3-4 kitab varsa, o zaman xəbərdarlıq edirik, artıq 5 kitab varsa, ona yeni kitab vermirik.
-- Əgər tələbə bu kitabı götürə bilərsə, S_Cards cədvəlinə sətir əlavə edin və Kitablar cədvəlində sütunların sayını yeniləyin.
CREATE PROCEDURE sp_StudentTakesBook
@stdId int, @bookId int
AS
BEGIN
	IF(@stdId > 0 AND @bookId > 0)
	BEGIN
		IF ((SELECT Quantity FROM Books
		WHERE Id = @bookId) > 0)
		BEGIN
			IF((SELECT COUNT(Id_Book) FROM S_Cards
			GROUP BY Id_Student) >= 5)
			PRINT 'kitab goture bilmersiz(limit dolub)'
			ELSE
			BEGIN 
				INSERT INTO S_Cards(Id, Id_Student, Id_Book, DateOut, Id_Lib)
				VALUES(105, @stdId, @bookId, GETDATE(),1)
				
				UPDATE Books
				SET Quantity -= 1
				FROM Books
				WHERE @bookId = Id
			END
		END
		ELSE
		PRINT 'Bu kitabdan satisda yoxdu!'
	END
	ELSE
	PRINT 'Id 0-dan boyuk olmalidir!'
END

EXEC sp_StudentTakesBook 2, 2

--8. SP "Teacher takes the book."
CREATE PROCEDURE sp_TeacherTakesBook
@tchId int, @bookId int
AS
BEGIN
	IF(@tchId > 0 AND @bookId > 0)
	BEGIN
		IF ((SELECT Quantity FROM Books
		WHERE Id = @bookId) > 0)
		BEGIN
			IF((SELECT COUNT(Id_Book) FROM S_Cards
			GROUP BY Id_Student) >= 5)
			PRINT 'kitab goture bilmersiz(limit dolub)'
			ELSE
			BEGIN 
				INSERT INTO T_Cards(Id, Id_Teacher, Id_Book, DateOut, Id_Lib)
				VALUES(105, @tchId, @bookId, GETDATE(),1)
				
				UPDATE Books
				SET Quantity -= 1
				FROM Books
				WHERE @bookId = Id
			END
		END
		ELSE
		PRINT 'Bu kitabdan satisda yoxdu!'
	END
	ELSE
	PRINT 'Id 0-dan boyuk olmalidir!'
END

EXECUTE sp_TeacherTakesBook 4, 1

--9. SP "The student returns the book." SP receives Student's Id and Book's Id. In the table S_Cards information is entered about the return of the book. Also you need add quantity in table Books. If the student has kept the book for more than a year, then he is fined.
CREATE PROCEDURE sp_StudentReturnsBook
@stdId int, @bookId int
AS
BEGIN
	IF(@stdId > 0 AND @bookId > 0)
	BEGIN
		IF(EXISTS(SELECT * FROM S_Cards
		   WHERE Id_Student = @stdId AND DateIn IS NULL))
		BEGIN
			UPDATE Books
			SET Quantity += 1
			FROM Books
			WHERE @bookId = Id

			UPDATE S_Cards
			SET DateIn = GETDATE()
			FROM S_Cards
			WHERE @stdId = Id_Student

			IF((SELECT DATEDIFF(year, S_Cards.DateOut, S_Cards.DateIn) FROM S_Cards WHERE @stdId = Id_Student AND Id_Book = @bookId) >= 1)
			   PRINT 'Cerime olunacaq!(Kitabin qaytarilma muddeti 1ilden coxdur)'
		END
	END
	ELSE
	PRINT 'Id 0-dan boyuk olmalidir!'
END

EXEC sp_StudentReturnsBook 21, 4

--10. SP "Teacher returns book".

CREATE PROCEDURE sp_TeacherReturnsBook
@tchId int, @bookId int
AS
BEGIN
	IF(@tchId > 0 AND @bookId > 0)
	BEGIN
		IF(EXISTS(SELECT * FROM T_Cards
		   WHERE Id_Teacher = @tchId AND DateIn IS NULL))
		BEGIN
			UPDATE Books
			SET Quantity += 1
			FROM Books
			WHERE @bookId = Id

			UPDATE T_Cards
			SET DateIn = GETDATE()
			FROM T_Cards
			WHERE @tchId = Id_Teacher

			IF((SELECT DATEDIFF(year, T_Cards.DateOut, T_Cards.DateIn) FROM T_Cards WHERE @tchId = Id_Teacher AND Id_Book = @bookId) >= 1)
			   PRINT 'Cerime olunacaq!(Kitabin qaytarilma muddeti 1ilden coxdur)'
		END
	END
	ELSE
	PRINT 'Id 0-dan boyuk olmalidir!'
END

EXEC sp_TeacherReturnsBook 10, 2
