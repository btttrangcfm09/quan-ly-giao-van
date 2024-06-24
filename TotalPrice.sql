#function tinh tien ship
DELIMITER $$
CREATE FUNCTION ShipPrice( OrderServiceID char(5) )
RETURNS decimal(12, 3)
DETERMINISTIC
BEGIN
	declare OrderShipPrice decimal(12,3) default 0;
	select Price
    into OrderShipPrice
    from Service
    where OrderServiceID = ServiceID;
return (OrderShipPrice);
END$$ 
DELIMITER ;

#function tinh tien don
DELIMITER $$
CREATE FUNCTION OrderPrice( OrderItemID char(5), Payer varchar(15))
RETURNS decimal(12, 3)
DETERMINISTIC
BEGIN
	declare OrderPrice decimal(12,3) default 0;
	select sum(itemprice)
    into OrderPrice
    from orderdetails
    where OrderItemID = OrderID
    group by OrderID;
return (OrderPrice);
END$$ 
DELIMITER ;

#function tinh tien pp cod, 
#drop function OrderPrice;
DELIMITER $$
CREATE FUNCTION OrderCod( OrderItemID char(5), Payer varchar(15))
RETURNS decimal(12, 3)
DETERMINISTIC
BEGIN
	declare ShipPrice decimal(12,3) default 0;
	declare OrderCod decimal(12,3) default 0;
    if Payer = 'nguoi nhan'
    then
	select ShipPrice(ServiceID)
    into ShipPrice
    from product
    where OrderItemID = OrderID;
    set OrderCod = ShipPrice*0.2;
    else set OrderCod = 0.00;
    end if;
return (OrderCod);
END$$ 
DELIMITER ;

#function tinh pp hang
#drop function OrderSurcharge;
DELIMITER $$
CREATE FUNCTION OrderSurcharge(OrderItemID char(5))
RETURNS decimal(12, 3)
DETERMINISTIC
BEGIN
	declare OrderSurcharge decimal(12,3) default 0;
    declare ItemSurcharge decimal(12,3) default 0;
    declare ShipPrice decimal(12,3) default 0;
    declare OrderCod decimal(12,3);
    #Xac dinh % phu phi
	select sum(Surcharge.price)
    into ItemSurcharge
    from Surcharge, OrderDetails
    where OrderItemID = OrderID and OrderDetails.SurchargeID = Surcharge.SurchargeID
    group by OrderID;
    select ShipPrice(ServiceID)
    into ShipPrice
    from product
    where OrderItemID = OrderID;
    select OrderCod(OrderID, Payer)
    into OrderCod
	from product
    where OrderItemID = OrderID;
    set OrderSurcharge = (ShipPrice+OrderCod)*ItemSurcharge;
return (OrderSurcharge);
END$$ 
DELIMITER ;

#function tinh tong tien
DELIMITER $$
CREATE FUNCTION Total(OrderItemID char(5))
RETURNS decimal(12, 3)
DETERMINISTIC
BEGIN
	declare ShipPrice decimal(12,3) default 0;
    declare OrderPrice decimal(12,3) default 0;
    declare OrderCod decimal(12,3) default 0;
    declare ShipSurcharge decimal(12,3) default 0;
    declare Total decimal(12,3) default 0;
    #Xac dinh % phu phi
    select ShipPrice(ServiceID)
    into ShipPrice
    from product
    where OrderItemID = OrderID;
    select OrderPrice(OrderID, Payer)
    into OrderPrice
    from product
    where OrderItemID = OrderID;
    select OrderCod(OrderID, Payer)
    into OrderCod
    from product
    where OrderItemID = OrderID;
    select OrderSurcharge(OrderID)
    into ShipSurcharge
    from product
    where OrderItemID = OrderID;
    set total = ShipPrice + OrderPrice + OrderCod + ShipSurcharge;
return (total);
END$$ 
DELIMITER ;

#Tinh so tien thu nguoi nhan
DELIMITER $$
CREATE FUNCTION RecipientPay( OrderItemID char(5), Payer varchar(15))
RETURNS decimal(12, 3)
DETERMINISTIC
BEGIN
	declare RecipientPay decimal(12,3) default 0;
	declare total decimal(12,3) default 0;
    if Payer = 'nguoi nhan'
    then
	select total(OrderID)
    into total
    from product
    where OrderItemID = OrderID;
    set RecipientPay = total;
    else set RecipientPay = 0.00;
    end if;
return (RecipientPay);
END$$
DELIMITER ;

#drop function total;
use qlgv;
create view PriceTotal as
select OrderID, ServiceID, ShipPrice(ServiceID) as ShipPrice, OrderPrice(OrderID, Payer) as OrderPrice, 
OrderCod(OrderID, Payer) as OrderCod, OrderSurcharge(OrderID) as ShipSurcharge, Total(OrderID) as Total,
RecipientPay(OrderID, Payer) as RecipientPay
from product;

	