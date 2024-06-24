create database qlgv;
use qlgv;
#drop database qlgv;
# tao bang kho
CREATE TABLE Warehouse (
    WarehouseID CHAR(4) PRIMARY KEY,
    WareName VARCHAR(30) NOT NULL,
    City VARCHAR(40) NOT NULL,
    District VARCHAR(30),
    Ward VARCHAR(30),
    Address VARCHAR(30)
);

#tao bang dich vu
CREATE TABLE Service (
    ServiceID CHAR(5) PRIMARY KEY,
    ServiceName VARCHAR(20),
    Price DECIMAL(12,3) not null,
    MaxDistance SMALLINT
);
alter table Service
modify MaxDistance char(6); 

# tao bang don hang
CREATE TABLE Product (
    OrderID CHAR(5) PRIMARY KEY,
#   Total DECIMAL(12,3) not null,
    Payer VARCHAR(15) not null,
    PickupCity VARCHAR(50) not null,
    PickupDistrict VARCHAR(30),
    PickupWard VARCHAR(30),
    PickupAddress VARCHAR(45) not null,
    RecipientName VARCHAR(30) not null,
    PhoneRecipient VARCHAR(15) not null,
    DeliveryCity VARCHAR(50),
    DeliveryDistrict VARCHAR(45),
    DeliveryWard VARCHAR(45),
    DeliveryAddress VARCHAR(45) not null,
#    CurrentWarehouseID CHAR(5) default 'K000',
#   OrderStatus VARCHAR(20) default 'Dang xu ly',
    ServiceID CHAR(5)
);
#them constraint cho ServiceID
ALTER TABLE Product
ADD CONSTRAINT Service_ID
FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
on delete cascade
on update cascade;

#bang nhap kho / xuat kho
CREATE TABLE ImportExport (
	OrderID CHAR(5),
    WarehouseID CHAR(5),
    InboundDate DATE not null,
    OutboundDate DATE default NUll,
    constraint ID primary key (WarehouseID, OrderID),
    constraint Warehouse_ID foreign key (WarehouseID) REFERENCES Warehouse(WarehouseID)
    on delete cascade
	on update cascade,
    constraint OrderID foreign key (OrderID) REFERENCES Product(OrderID)
    on delete cascade
	on update cascade
);

# bang nguoi dung
CREATE TABLE AccUser (
    UserID CHAR(5) PRIMARY KEY,
    LastName VARCHAR(10),
    MiddleName VARCHAR(10),
	FirstName VARCHAR(10) not null,
    Birthday DATE,
    Gender CHAR(3),
    Phone VARCHAR(10) unique not null,
    City VARCHAR(30),
    District VARCHAR(45),
    Ware VARCHAR(45),
    Address VARCHAR(45)
);

#bang tao don hang
CREATE TABLE OrderCreate (
    OrderID CHAR(5),
    GiverID CHAR(5),
    ReciverID char(5),
    OrderDate DATE not null,
    constraint primary key (GiverID, OrderID),
    constraint foreign key (GiverID) REFERENCES AccUser(UserID)
    on delete cascade
	on update cascade,
    constraint foreign key (OrderID) REFERENCES Product(OrderID)
    on delete cascade
	on update cascade
);


# Tao trigger de ngan khi add du lieu vao 2 cot reciverID = OrderID
#DROP TRIGGER before_insert_OrderCreate;
DELIMITER $$
CREATE TRIGGER before_insert_OrderCreate
     BEFORE insert ON OrderCreate
     for each row
BEGIN
     IF new.GiverID = new.ReciverID
     then 
		  signal SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Nguoi gui khong the tu dat don hang cua minh!';
	 end if;
END $$
DELIMITER ;

#DROP TRIGGER before_update_OrderCreate
DELIMITER $$
CREATE TRIGGER before_update_OrderCreate
     BEFORE update ON OrderCreate
     for each row
BEGIN
     IF new.GiverID = old.ReciverID or old.GiverID = new.ReciverID or new.GiverID = new.ReciverID
     then 
		  signal SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Nguoi gui khong the tu dat don hang cua minh!';
	 end if;
END $$
DELIMITER ;

#Tao bang shipper
CREATE TABLE Shipper (
    EmployeeID CHAR(5) PRIMARY KEY,
    LastName VARCHAR(10),
    MiddleName VARCHAR(10),
    FirstName VARCHAR(10) not null,
    Gender CHAR(6),
    Birthday DATE,
    Phone VARCHAR(10) unique not null,
    HomeTown VARCHAR(45) not null
);
desc Shipper;
#Tao bang giao hang
CREATE TABLE Send (
    EmployeeID CHAR(5),
    OrderID CHAR(5),
    ReceiptDate DATE, #ngay nhan don
    EstimatedDate DATE, # ngay giao hang du kien = ngay nhan don + 4
    ActualDate DATE, # ngay giao hang thuc te - tu nhap 
    SendStatus varchar(30), #Trang thai don giao - tu nhap
    constraint SendID primary key (EmployeeID, OrderID),
    constraint Employee_ID foreign key (EmployeeID) REFERENCES Shipper(EmployeeID)
    on delete cascade
	on update cascade,
    constraint foreign key (OrderID) REFERENCES Product(OrderID)
    on delete cascade
	on update cascade
);
#desc Send;
#Tao bang dich vu
create table Surcharge (
    SurchargeID char(5) primary key,
    SurchargeName varchar(20),
    Price decimal(5,2)
);
#desc Surcharge;

#Tao bang chi tiet don hang
create table OrderDetails (
    ItemID char(10),
    OrderID char(5),
    ItemName varchar(30) not null,
    SurchargeID varchar(20),
    Weight decimal(18,2) not null,
    constraint DetailsID primary key (ItemID, OrderID),
    constraint foreign key (OrderID) REFERENCES Product(OrderID)
    on delete cascade
	on update cascade,
    constraint foreign key (SurchargeID) REFERENCES Surcharge(SurchargeID)
    on delete cascade
	on update cascade
);
alter table OrderDetails
add itemprice decimal(20,3);

alter table orderdetails 
drop primary key;   
alter table orderdetails
add primary key(ItemID); 
#desc orderdetails;

# Trigger for Statusofproduct
create table Statusofproduct(
       OrderID CHAR(5) PRIMARY KEY,
       CurrentWarehouseID CHAR(5),
       OrderStatus VARCHAR(30)
);
select * from Statusofproduct;

#DROP TRIGGER after_create_product;
# mỗi khi tạo một đơn hàng trong product sẽ thêm vao bảng Statusofproduct các thông tin dưới đây
DELIMITER $$
CREATE TRIGGER after_create_product
       AFTER INSERT ON product
       for each row
BEGIN 
       INSERT INTO Statusofproduct
       SET OrderID = new.OrderID,
           CurrentWarehouseID = '0000',
           OrderStatus = 'Dang xu ly';
END$$
DELIMITER ;

#drop TRIGGER after_delete_product;
#khi don hang bi xoa di khoi bang product -> update OrderStatus = 'don hang da bi huy'
DELIMITER $$
CREATE TRIGGER after_delete_product
       AFTER delete ON product
       for each row
BEGIN 
         UPDATE Statusofproduct as sta
         SET OrderStatus = 'Don hang da bi huy'
         where OLD.OrderID = sta.OrderID and sta.CurrentWarehouseID = '0000';
END$$
DELIMITER ;

#Drop TRIGGER after_insert_Warehouse;
# mỗi khi thêm vào importexport thì update bảng statusofproduct
DELIMITER $$
CREATE TRIGGER after_insert_Warehouse
       AFTER INSERT ON importexport
       FOR EACH ROW
BEGIN   
    IF new.OutboundDate is not null
    THEN 
         UPDATE Statusofproduct as Sta
         SET CurrentWarehouseID = NEW.WarehouseID,
			 OrderStatus = 'Da roi kho'
         WHERE NEW.OrderID = Sta.OrderID;
	ELSE 
         UPDATE Statusofproduct as Sta
         SET CurrentWarehouseID = NEW.WarehouseID,
			 OrderStatus = 'Dang trong kho'
         WHERE NEW.OrderID = Sta.OrderID;
    end if;
END$$ 
DELIMITER ;

#DROP TRIGGER after_updateexportdate_Warehouse;
#MOI KHI UPDATE VAO importexport, ExportDate != NULL -> update Statusofproduct
DELIMITER $$
CREATE TRIGGER after_updateexportdate_Warehouse
AFTER Update   ON importexport
FOR EACH ROW
BEGIN   
    IF new.OutboundDate is not null
    THEN 
         UPDATE Statusofproduct as Sta
         SET OrderStatus = 'Da roi kho'
         WHERE NEW.OrderID = Sta.OrderID;
    end if;
END$$ 
DELIMITER ;

#DROP TRIGGER after_insert_send;
# moi khi insert vao bang send thi update bang statusofproduct
DELIMITER $$
CREATE TRIGGER after_insert_send
AFTER INSERT ON send
FOR EACH ROW
BEGIN   
    IF NEW.SendStatus IS NULL
    THEN
         UPDATE Statusofproduct as sta
         SET CurrentWarehouseID = 'Done',
              OrderStatus = 'Dang giao hang'
         WHERE NEW.OrderID = sta.OrderID;
	ELSE 
         UPDATE Statusofproduct as sta
         SET CurrentWarehouseID = 'Done',
              OrderStatus = NEW.SendStatus
         WHERE NEW.OrderID = sta.OrderID;   
	end if;
END$$ 
DELIMITER ;

#Mỗi khi update mà actualdate != null thì hàng đã giao thành công
DELIMITER $$
CREATE TRIGGER after_update_send
AFTER UPDATE ON send
FOR EACH ROW
BEGIN   
   IF OLD.SendStatus <> NEW.SendStatus THEN
         UPDATE Statusofproduct as sta
         SET OrderStatus = NEW.SendStatus
         where NEW.OrderID = sta.OrderID;
    end if;
END$$ 
DELIMITER ;
#select * from Statusofproduct;


# trigger do chan tao
-- Thêm phần này vào cuối file gv nhá
-- Tạo bảng log để lưu trữ thông tin cập nhật của Warehouse
CREATE TABLE WarehouseLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    WarehouseID CHAR(4),
    OldWareName VARCHAR(30),
    NewWareName VARCHAR(30),
    OldCity VARCHAR(40),
    NewCity VARCHAR(40),
    OldDistrict VARCHAR(30),
    NewDistrict VARCHAR(30),
    OldWard VARCHAR(30),
    NewWard VARCHAR(30),
    OldAddress VARCHAR(30),
    NewAddress VARCHAR(30),
    ChangeTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo trigger để lưu trữ thông tin cập nhật vào bảng log sau mỗi lần cập nhật bảng Warehouse
DELIMITER //

CREATE TRIGGER after_warehouse_update
AFTER UPDATE ON Warehouse
FOR EACH ROW
BEGIN
    INSERT INTO WarehouseLog (WarehouseID, OldWareName, NewWareName, OldCity, NewCity, OldDistrict, NewDistrict, OldWard, NewWard, OldAddress, NewAddress)
    VALUES (OLD.WarehouseID, OLD.WareName, NEW.WareName, OLD.City, NEW.City, OLD.District, NEW.District, OLD.Ward, NEW.Ward, OLD.Address, NEW.Address);
END //

DELIMITER ;
