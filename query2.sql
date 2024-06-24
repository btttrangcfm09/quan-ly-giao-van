use qlgv;
#Chon so nguoi tao don trong nam 2024, sap xep theo thu tu so don 
create index Order_Date on OrderCreate(OrderDate);
#drop index Order_Date on OrderCreate;
#explain 
select GiverID, count(orderID) as So_Don
from OrderCreate
where orderDate >= '2024-01-01'
group by GiverID
order by count(orderID) desc;


#Biet nguoi dung co so tien ship(Khong tinh gia tri don) tren 100.000 hoac co so don > 3 la khach hang tiem nang. Hay liet ke thong tin cua nhung user la kh tiem nang
select * from accuser
where userid in (
	select giverid
	from ordercreate, PriceTotal
	where ordercreate.OrderID = PriceTotal.OrderID
	group by GiverID
	having (sum(ShipPrice) + sum(OrderCod) + sum(ShipSurcharge)) > 150000
);

select * from PriceTotal;

#Chon ra nhung nguoi dung tao tai khoan nhung chua gui don nao
select * from accuser
where userid not in (
	select giverid
    from ordercreate
);

#Chọn ra những tk đã từng gửi ở 2 địa chỉ gửi hàng trở lên

use qlgv;
#Chọn ra những tk đã từng gửi đơn hàng có địa chỉ lấy hàng khác địa chỉ user


#Chon ra ten, tuoi, gioi tinh user co dc o Ha Noi
#Revenue Manager, Customer Manager, 
select lastname, middlename,firstname, gender,phone from accuser
where city = 'Ha Noi';









#index
create index give_id on OrderCreate(GiverID);
create index order_status on Statusofproduct(OrderStatus);


#Loc ra top 10 kho hang co nhieu don hang di qua nhat
#Revenue Manager
select warehouse.WarehouseID, Warename, count(orderid) as SoDon
from Warehouse, importexport
where warehouse.warehouseid = importexport.warehouseid
group by warehouseid
order by SoDon desc
limit 10;

#Neu shipper giao đúng hạn trên 50% số đơn thì là shipper đạt tiêu chuẩn. Hãy lọc ra những shipper đạt tiêu chuẩn
#Revenue Manager và Shipper có thể dùng truy vấn này
DELIMITER $$
CREATE FUNCTION EnableOrderPercent( PEmployeeID char(6) )
RETURNS decimal(5,2)
DETERMINISTIC
BEGIN
	declare OK int default 0;
    declare total int default 0;
    declare percent decimal(5,2) default 0;
    select count(orderid)
    into total
    from send
    where PEmployeeID = EmployeeID
    group by EmployeeID;
	select count(orderid)
    into ok
    from send
    where PEmployeeID = EmployeeID and EstimatedDate <= ActualDate
    group by EmployeeID;
    if (total = 0) then set percent = 0;
    else set percent = ok/total*100;
    end if;
return (percent);
END$$ 
DELIMITER ;
#drop function Percent;
select distinct shipper.*, count(orderid) as SoDon, EnableOrderPercent(shipper.EmployeeID) as SuccessPercent
from shipper, send
where shipper.employeeid = send.employeeid
group by shipper.employeeid
having SuccessPercent >= 50.00;

select distinct shipper.*, Percent(shipper.EmployeeID) as SuccessPercent
from shipper;
#having SuccessPercent >= 50.00;

#Ty le phan phoi don hang nhan trong o cac tinh
DELIMITER $$
Create function PercentCity( Cityname varchar(20))
returns decimal(5,3)
DETERMINISTIC
BEGIN
	declare NumberofOrder smallint;
    declare NumberOrderCity smallint;
    declare PercentCity decimal(5,3);
    select count(*) into NumberofOrder from Product;
    select count(OrderID) into NumberOrderCity from Product
    where Cityname = DeliveryCity
    group by Cityname;
    set PercentCity = NumberOrderCity/NumberofOrder*100;
return (PercentCity);
END$$
DELIMITER ;
select distinct DeliveryCity as City, count(OrderID) as TongSoDon, PercentCity(DeliveryCity) as Ty_le_phan_phoi from Product
group by DeliveryCity;

#