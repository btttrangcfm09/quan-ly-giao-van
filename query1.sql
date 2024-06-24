#index
create index give_id on OrderCreate(GiverID);
create index order_status on Statusofproduct(OrderStatus);
# ty le don hang giao thanh cong cua tung account
# drop function  Successpercent;
DELIMITER $$
CREATE FUNCTION Successpercent(UserID CHAR(5))
RETURNS DECIMAL(5,2)
DETERMINISTIC 
BEGIN
    DECLARE success_rate DECIMAL(5,2) DEFAULT 0.00;
    # tao CTEtable de luu OrderID cua don hang va trang thai cua no.
    WITH CTEtable AS (
        SELECT POG.OrderID AS Orde, S.OrderStatus AS Sttus
        FROM Statusofproduct AS S
        INNER JOIN (
            SELECT OrderID
            FROM OrderCreate
            WHERE GiverID = UserID
        ) AS POG ON S.OrderID = POG.OrderID
    )
    SELECT ROUND((CAST((SELECT COUNT(Orde) FROM CTEtable WHERE Sttus = 'Thanh cong') AS DECIMAL) 
                  / COUNT(Orde)) * 100, 2)
    INTO success_rate
    FROM CTEtable;
    RETURN success_rate;
END$$
DELIMITER ;

SELECT distinct UserID, 
CASE 
    When userid in (select distinct giverid from ordercreate) then Successpercent(UserID) 
    else 0.00
    end AS `Tỷ lệ đơn hàng được giao thành công`
FROM accuser
Order by UserID;

#trong tat ca cac don hang da gui thi so don hang thanh cong, hoan, huy lan luot la
select * from Statusofproduct;
select Round(((select count(orderID) from Statusofproduct
		 where OrderStatus = 'Thanh cong'
		 group by OrderStatus) / count(OrderID)) * 100, 2)
	   as `Tỷ lệ đơn hàng được giao thành công`,
       Round(((select count(orderID) from Statusofproduct
		 where OrderStatus = 'Hoan'
		 group by OrderStatus) / count(OrderID)) * 100, 2)
	   as `Tỷ lệ đơn hàng bị hoàn lại`,
       Round(((select count(orderID) from Statusofproduct
		 where OrderStatus = 'Don hang da bi huy'
		 group by OrderStatus) / count(OrderID)) * 100, 2)
	   as `Tỷ lệ đơn hàng đã bị hủy`
from Statusofproduct;

#Dich vu nao duoc dung nhieu nhat?
select p.ServiceID ,count(OrderID) as c, servicename
from product as p
     inner join Service as S
     on S.ServiceID = p.ServiceID
group by S.ServiceID
order by c desc
limit 1;

#Nhung Shipper nao giao nhieu don hang nhat
create view temtable as 
select sh.EmployeeID, sh.Lastname, sh.MiddleName, sh.FirstName, count(OrderID) as `Số lượng đơn`
from send as s
     inner join Shipper as sh
     on s.EmployeeID = sh.EmployeeID
group by sh.EmployeeID
order by `Số lượng đơn` desc;
select * from temtable
where `Số lượng đơn` in (select max(`Số lượng đơn`) from temtable);



#cac don hang van dang trong qua trinh van chuyen giua cac kho?
explain select OrderID
from Statusofproduct 
where OrderStatus = 'Dang trong kho' or OrderStatus = 'Da roi kho';

#Tao mot procedure show cac don hang da duoc van chuyen qua kho trong ngay a den ngay b
Create index name_of_warehouse on warehouse(WareName);
Create index ID_In_out_Warehouse on importexport(WarehouseID, InboundDate, OutboundDate);
#drop procedure show_don_hang;
DELIMITER $$
CREATE procedure Show_don_hang(tenkho VARCHAR(30), ngaya DATE, ngayb DATE)
BEGIN 
    SELECT OrderID AS `Đơn hàng`
     from importexport AS i
     WHERE i.WarehouseID in (select WarehouseID from warehouse where WareName = tenkho) AND 
		   i.InboundDate >= ngaya AND 
           i.OutboundDate <= ngayb;
END$$
DELIMITER ;

CALL Show_don_hang('Kho Bac Giang', '2016-05-26', '2024-06-03');

#Tinh thoi gian trung binh xu ly don hang tu luc tao den luc giao thanh cong cua tung dich vu van chuyen

  # tinh so ngay ke tu khi tao dich vu cho den khi dc giao cua 1 don hang 
   # drop FUNCTION SUM_OF_DAY;
   DELIMITER $$
    CREATE FUNCTION SUM_OF_DAY(Ma_van_don CHAR(5))
    RETURNS INT 
    DETERMINISTIC
    BEGIN
        DECLARE Sumofday INT;
        SELECT DATEDIFF((SELECT ActualDate from send where OrderID = Ma_van_don), OrderDate)
        INTO Sumofday 
        FROM ordercreate
        WHERE OrderID = Ma_van_don;
        return Sumofday;
    END $$
    DELIMITER ;
# Tinh trung binh so ngay da giao cua cac don hang thanh cong cua 1 dich vu
# drop function tr;
DELIMITER $$
CREATE FUNCTION tr(Ma_dich_vu CHAR(5))
RETURNS INT 
DETERMINISTIC
BEGIN
    DECLARE Trung_binh INT;
    select AVG(SUM_OF_DAY(P.OrderID))
    into Trung_binh
    from (Product as P 
          inner join statusofproduct as status on P.OrderID = status.OrderID)
    where OrderStatus = 'Thanh cong' and 
          ServiceID = Ma_dich_vu;
	#select * from ordercreate order by OrderID;
    #select * from send order by OrderID;
    #select * from product where ServiceID = 'S303';
    return Trung_binh;
END $$
DELIMITER ;
#Bang show ket qua
select serviceid, servicename, 
CASE
    when tr(serviceid) is not null THEN tr(serviceid)
    else 'Chua duoc su dung'
end as `Số ngày giao trung binh`
from service; 

          
