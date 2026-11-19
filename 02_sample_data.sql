INSERT INTO publisher VALUES
(1,'Pearson','Noida','info@pearson.example'),(2,'McGraw Hill','New Delhi','contact@mcgraw.example'),
(3,'O''Reilly','Sebastopol','hello@oreilly.example'),(4,'Penguin','Gurugram','books@penguin.example'),
(5,'Springer','Berlin','sales@springer.example'),(6,'Oxford Press','Oxford','orders@oup.example');
INSERT INTO author VALUES
(1,'Abraham','Silberschatz','USA'),(2,'Henry','Korth','USA'),(3,'Ramez','Elmasri','USA'),
(4,'Thomas','Cormen','USA'),(5,'Robert','Martin','USA'),(6,'Chetan','Bhagat','India'),
(7,'APJ','Abdul Kalam','India'),(8,'Andrew','Tanenbaum','Netherlands');
INSERT INTO category VALUES (1,'Databases'),(2,'Algorithms'),(3,'Software Engineering'),(4,'Fiction'),(5,'Biography'),(6,'Operating Systems');
INSERT INTO resource VALUES
(1,'Database System Concepts','9780078022159','PHYSICAL',2,1,2019,'English'),
(2,'Fundamentals of Database Systems','9780133970777','PHYSICAL',1,1,2016,'English'),
(3,'Introduction to Algorithms','9780262046305','PHYSICAL',2,2,2022,'English'),
(4,'Clean Code','9780132350884','PHYSICAL',1,3,2008,'English'),
(5,'Five Point Someone','9788129104595','PHYSICAL',4,4,2004,'English'),
(6,'Wings of Fire','9788173711466','PHYSICAL',4,5,1999,'English'),
(7,'Modern Operating Systems','9780133591620','PHYSICAL',1,6,2014,'English'),
(8,'Half Girlfriend','9788129135728','PHYSICAL',4,4,2014,'English'),
(9,'Learning SQL','9781492057611','PHYSICAL',3,1,2020,'English'),
(13,'Computer Networks','9780132126953','PHYSICAL',1,6,2010,'English'),
(10,'SQL Performance Explained (e-book)','9783950307825','DIGITAL',5,1,2012,'English'),
(11,'Designing Data-Intensive Apps (e-book)','9781491903100','DIGITAL',3,1,2017,'English'),
(12,'Algorithms Illuminated (e-book)','9780999282908','DIGITAL',5,2,2018,'English');
INSERT INTO resource_author VALUES
(1,1,1),(1,2,2),(2,3,1),(3,4,1),(4,5,1),(5,6,1),(6,7,1),(7,8,1),(8,6,1),(9,2,1),(10,3,1),(11,2,1),(12,4,1);
INSERT INTO item (item_id,resource_id,barcode,shelf_location,access_url) VALUES
(1,1,'LIB-0001','A-01',NULL),(2,1,'LIB-0002','A-01',NULL),(3,2,'LIB-0003','A-02',NULL),(4,2,'LIB-0004','A-02',NULL),
(5,3,'LIB-0005','B-01',NULL),(6,4,'LIB-0006','C-03',NULL),(7,5,'LIB-0007','D-01',NULL),(8,5,'LIB-0008','D-01',NULL),
(9,6,'LIB-0009','E-02',NULL),(10,7,'LIB-0010','B-04',NULL),(11,8,'LIB-0011','D-02',NULL),(12,9,'LIB-0012','A-03',NULL),(16,13,'LIB-0016','B-05',NULL);
INSERT INTO item (item_id,resource_id,barcode,shelf_location,access_url) VALUES
(13,10,NULL,NULL,'https://lib.example/e/sql-perf'),(14,11,NULL,NULL,'https://lib.example/e/ddia'),(15,12,NULL,NULL,'https://lib.example/e/algo-ill');
INSERT INTO membership_type VALUES (1,'Student',3,14,2.00,200),(2,'Faculty',10,30,1.00,500),(3,'Public',2,7,5.00,300);
INSERT INTO member VALUES
(1,'Aarav Sharma','aarav@example.com','9000000001','2025-07-01','2026-06-30',1,'EXPIRED'),
(2,'Dr. Meera Iyer','meera@example.com','9000000002','2024-01-10','2027-01-09',2,'ACTIVE'),
(3,'Rohan Gupta','rohan@example.com','9000000003','2026-01-05','2027-01-04',3,'ACTIVE'),
(4,'Simran Kaur','simran@example.com','9000000004','2026-07-15','2027-07-14',1,'ACTIVE'),
(5,'Karan Verma','karan@example.com','9000000005','2026-07-15','2027-07-14',1,'ACTIVE'),
(6,'Ananya Das','ananya@example.com','9000000006','2026-08-01','2027-07-31',1,'ACTIVE'),
(7,'Prof. Rakesh Nair','rakesh@example.com','9000000007','2023-06-01','2027-05-31',2,'ACTIVE'),
(8,'Isha Malhotra','isha@example.com','9000000008','2026-09-01','2027-08-31',1,'SUSPENDED');
-- Issue loans (return_date NULL), then return some via UPDATE so triggers fire
INSERT INTO loan (loan_id,member_id,item_id,issue_date,due_date) VALUES
(1,4,1,'2026-08-01','2026-08-15'),(2,4,3,'2026-08-20','2026-09-03'),(3,2,1,'2026-08-16','2026-09-15'),
(4,3,5,'2026-09-05','2026-09-12'),(5,5,2,'2026-09-02','2026-09-16'),(6,6,7,'2026-09-10','2026-09-24'),
(7,7,10,'2026-09-12','2026-10-12'),(8,4,6,'2026-09-20','2026-10-04'),(9,5,1,'2026-09-25','2026-10-09'),
(10,6,12,'2026-10-01','2026-10-15'),(11,3,9,'2026-10-03','2026-10-10'),(12,2,4,'2026-10-05','2026-11-04'),
(13,7,2,'2026-10-06','2026-11-05'),(14,4,13,'2026-10-08','2026-10-22'),(15,5,14,'2026-10-09','2026-10-23'),
(16,6,13,'2026-10-12','2026-10-26'),(17,2,14,'2026-10-14','2026-11-13'),(18,3,11,'2026-10-15','2026-10-22'),
(19,5,5,'2026-10-20','2026-11-03'),(20,4,1,'2026-10-25','2026-11-08'),(21,6,8,'2026-10-28','2026-11-11'),
(22,7,15,'2026-11-01','2026-12-01'),(23,2,3,'2026-11-02','2026-12-02'),(24,5,9,'2026-11-05','2026-11-19');
UPDATE loan SET return_date='2026-08-14' WHERE loan_id=1;
UPDATE loan SET return_date='2026-09-10' WHERE loan_id=2;   -- 7 days late
UPDATE loan SET return_date='2026-09-14' WHERE loan_id=3;
UPDATE loan SET return_date='2026-09-20' WHERE loan_id=4;   -- 8 days late
UPDATE loan SET return_date='2026-09-30' WHERE loan_id=5;   -- 14 days late
UPDATE loan SET return_date='2026-09-23' WHERE loan_id=6;
UPDATE loan SET return_date='2026-10-10' WHERE loan_id=7;
UPDATE loan SET return_date='2026-10-04' WHERE loan_id=8;
UPDATE loan SET return_date='2026-10-20' WHERE loan_id=9;   -- 11 days late
UPDATE loan SET return_date='2026-10-14' WHERE loan_id=10;
UPDATE loan SET return_date='2026-10-17' WHERE loan_id=11;  -- 7 days late
UPDATE loan SET return_date='2026-11-02' WHERE loan_id=12;
UPDATE loan SET return_date='2026-10-21' WHERE loan_id=14;
UPDATE loan SET return_date='2026-10-25' WHERE loan_id=15;  -- 2 days late
UPDATE loan SET return_date='2026-10-26' WHERE loan_id=16;
UPDATE loan SET return_date='2026-10-30' WHERE loan_id=18;  -- 8 days late
UPDATE loan SET return_date='2026-11-03' WHERE loan_id=19;
UPDATE loan SET return_date='2026-11-07' WHERE loan_id=20;
-- still out: 13 (due 11-05, OVERDUE), 21 (due 11-11, OVERDUE), 17, 22, 23, 24 (not yet due)
INSERT INTO loan (loan_id,member_id,item_id,issue_date,due_date) VALUES (25,2,11,'2026-11-08','2026-12-08');
UPDATE fine SET paid_on='2026-09-12' WHERE loan_id IN (2,4);
INSERT INTO reservation VALUES
(1,6,1,'2026-11-01','2026-11-15','PENDING'),(2,5,8,'2026-11-03','2026-11-17','PENDING'),
(3,4,3,'2026-10-01','2026-10-15','FULFILLED'),(4,3,2,'2026-09-01','2026-09-10','EXPIRED');
