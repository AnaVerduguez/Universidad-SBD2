/* Clase del día 18/04/23
   Ejercicios de triggers */

--Creo la tabla empleado
create table empleado(
	idEmpleado numeric identity(1,1) not null,
	nombre nvarchar(30) not null,
	apellido nvarchar(30) not null,
	cuit numeric(11) not null,
	sueldoBruto smallmoney not null,
	fechaAlta datetime not null,
	fechaBaja datetime null,
	fechaModif datetime not null,
	constraint PK_empleado PRIMARY KEY (idEmpleado)
)

--Creo la tabla empleadoBajas
create table empleadoBajas(
	idEmpleado numeric not null,
	nombre nvarchar(30) not null,
	apellido nvarchar(30) not null,
	cuit numeric(11) not null,
	sueldoBruto smallmoney not null,
	fechaAlta datetime not null,
	fechaBaja datetime null,
	fechaModif datetime not null,
	constraint PK_proveedor PRIMARY KEY (idEmpleado)
)

--Creo la tabla actualizacionesSueldos 
create table actualizacionesSueldos(
	idEmpleado numeric not null,
	sueldoBrutoAnterior smallmoney not null,
	sueldoBrutoNuevo smallmoney not null,
	fechaModificacion datetime not null
)

--Creo el procedimiento almacenado que inserta un empleado 
create procedure empleado_ins
	@nombre nvarchar(30),
	@apellido nvarchar(30),
	@cuit numeric(11),
	@sueldoBruto smallmoney,
	@fechaAlta datetime,
	@idEmpleado numeric output
as
begin
	insert into empleado values(
		@nombre,
		@apellido,
		@cuit,
		@sueldoBruto,
		@fechaAlta,
		null,
		getdate()
	)
	select @idEmpleado = SCOPE_IDENTITY()
end

--Creo el procedimiento almacenado que elimina un empleado
create procedure empleado_del_fis
    @idEmpleado numeric
as
begin
	delete from empleado where idEmpleado = @idEmpleado
end

--Inserto los siguientes empleados:
exec empleado_ins 'Juan','Perez',11222222221,80000,'2023-01-01',null
exec empleado_ins 'Maria','Suarez',22333333332,90000,'2023-01-01',null
exec empleado_ins 'Daniel','Fernandez',33444444443,100000,'2022-01-01',null
exec empleado_ins 'Lucia','Gonzalez',44555555554,150000,'2020-01-01',null


/*-----------------------------------------------------------------------------------------*/
--1. Crear y testear un trigger que impida insertar dos empleados con el mismo cuit
CREATE TRIGGER trg_empleado_INS
ON empleado
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @cuit numeric(11)
    
    SELECT @cuit = empleado.cuit FROM empleado INNER JOIN inserted
    ON inserted.cuit = empleado.cuit

	--Si no hay ningun cuit, inserto el registro/Si no es nulo nisiquiera entra
    --Select @cuit as 'Veo qué tiene la variable @cuit'
    IF @cuit IS NULL
    BEGIN
        insert into empleado(nombre,apellido,cuit,sueldoBruto,fechaAlta,fechaBaja,fechaModif)
        SELECT
            inserted.nombre,
            inserted.apellido,
            inserted.cuit,
            inserted.SueldoBruto,
            inserted.fechaAlta,
            null,
            GETDATE()
        FROM
            inserted
    END
END

--Test
exec empleado_ins 'Test punto 1','Test',11222222221,80000,'2023-01-01',null
select  * from empleado
exec empleado_ins '1','Test',11222222220,80000,'2023-01-01',null
select  * from empleado


--2. Crear y testear un trigger para insertar el registro borrado físicamente en la tabla empleadoBajas.
create trigger trg_empleado_DEL
on empleado
for delete
as
begin
    INSERT INTO empleadoBajas
    SELECT TOP (1)
        deleted.idEmpleado,
        deleted.nombre,
        deleted.apellido,
        deleted.cuit,
        deleted.sueldoBruto,
        deleted.fechaAlta,
        getdate(),
        getdate()
    FROM deleted
END

--Test. Probamos que borre fisicamente realmente y que a su vez que inserte lo que borre
exec empleado_del_fis 18 --El ID a eliminar
select * from empleado
select * from empleadoBajas


--3. Crear y testear un trigger que al actualizar el sueldo de un empleado, inserte en la tabla actualizacionesSueldos el ID del empleado, el sueldo anterior, el nuevo y la fecha de modificación.
CREATE TRIGGER trg_SueldoNuevoEmpleado_UPD
ON empleado
FOR UPDATE
AS
BEGIN
INSERT INTO actualizacionesSueldos(idEmpleado,sueldoBrutoAnterior,sueldoBrutoNuevo,fechaModificacion)
 SELECT
	inserted.sueldoBrutoNuevo,
	deleted.SueldoBruto,
	inserted.SueldoBruto,

	GETDATE()

FROM
	inserted INNER JOIN deleted ON inserted.sueldoBrutoAnterior = deleted.sueldoBruto
END


--4. Crear y testear un trigger que inserte el sueldo anterior, el nuevo y la fecha de modificación cuando el aumento del sueldo sea igual o mayor al 50%.
CREATE TRIGGER trg_empleado_SueldoMayor50aumento_UPD
ON empleado
FOR UPDATE
AS
BEGIN
    INSERT INTO actualizacionesSueldos(idEmpleado, SueldoBrutoAnterior, SueldoBrutoNuevo,FechaModificacion)
        SELECT
            inserted.idEmpleado,
            deleted.SueldoBruto, --Valor anterior, antes de actualizar
            inserted.SueldoBruto,
            GETDATE()
        FROM
            inserted INNER JOIN deleted ON inserted.idEmpleado = deleted.idEmpleado
        WHERE
            inserted.SueldoBruto >= deleted.SueldoBruto * 1.5
END

--Test
select * from empleado
update empleado set sueldoBruto = 100001 where idEmpleado = 3
select * from empleado
select  * from actualizacionesSueldos
update empleado set sueldoBruto = 100000 where idEmpleado = 3
select * from empleado
select  * from actualizacionesSueldos
update empleado set sueldoBruto = 150000 where idEmpleado = 3
select * from empleado
select  * from actualizacionesSueldos



--5. Modificar el trigger del punto 3 para que sólo se active cuando el sueldo nuevo es diferente del sueldo actual.
ALTER TRIGGER trg_empleado_UPD
ON empleado
FOR UPDATE
AS
BEGIN
    INSERT INTO actualizacionesSueldos(idEmpleado, SueldoBrutoAnterior, SueldoBrutoNuevo,FechaModificacion)
        SELECT
            inserted.idEmpleado,
            deleted.SueldoBruto, --Valor anterior, antes de actualizar
            inserted.SueldoBruto,
            GETDATE()
        FROM
            inserted INNER JOIN deleted ON inserted.idEmpleado = deleted.idEmpleado
        WHERE
            inserted.SueldoBruto <> deleted.SueldoBruto
END

--Test
select * from empleado
update empleado set sueldoBruto = 90000 where idEmpleado = 2
select * from empleado
select  * from actualizacionesSueldos
update empleado set sueldoBruto = 90001 where idEmpleado = 2
select * from empleado
select  * from actualizacionesSueldos