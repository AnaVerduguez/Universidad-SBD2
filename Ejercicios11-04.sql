/* Clase del día 11/04/23
   Ejercicios en clase. */

--1. Creo una base de datos llamada universidad
create database universidad

use universidad

--2. Creo las tablas alumno, materia e inscripcion(tabla intermedia)
create table alumno(
    idAlumno numeric(18,0) primary key,
    nombre nvarchar(30) not null,
    apellido nvarchar(30) not null,
    fechaAlta datetime not null,
    fechaBaja datetime null,
    fechaModificacion datetime not null
)

create table inscripcion(
    idAlumno numeric not null,
    idMateria numeric not null,
    idTipoInscripcion numeric not null,
    fechaDesde datetime not null,
    fechaHasta datetime not null,
    constraint PK_inscrpcion PRIMARY KEY (
    idAlumno,
    idMateria,
    idTipoInscripcion,
    fechaDesde,
    fechaHasta)
)

create table materia(
    idMateria numeric identity(1,1) not null,
    descripcion nvarchar(30) not null,
    fechaAlta datetime not null,
    fechaBaja datetime null,
    fechaModif datetime not null,
    constraint PK_materia PRIMARY KEY (idMateria)
)

--Creo otra tabla de tipoInscripcion
create table tipoInscripcion(
    idTipoInscripcion numeric identity(1,1) not null,
    descripcion nvarchar(30) not null,
    constraint PK_tipoInscripcion PRIMARY KEY (idTipoInscripcion)
)

--3. Creo las relaciones entre las tablas

--Incripcion y Alumno
ALTER TABLE inscripcion
    ADD CONSTRAINT inscripcionAlumno
    FOREIGN KEY (idAlumno) REFERENCES alumno(idAlumno)

--Incripcion y Materia
ALTER TABLE inscripcion
    ADD CONSTRAINT inscripcionMateria
    FOREIGN KEY (idMateria) REFERENCES materia(idMateria)

--Incripcion y TipoInscripcion
ALTER TABLE inscripcion
    ADD CONSTRAINT inscripcionTipoInscripcion
    FOREIGN KEY (idTipoInscripcion) REFERENCES tipoInscripcion(idTipoInscripcion)


--4. Crear un SP que inserte una materia 
create procedure sp_materia_ins
    @descripcion varchar(30)
as
    insert into materia values(
    @descripcion,
    getdate(),
    null,
    getdate()
)

--Test-> pruebo si anda 
exec sp_materia_ins 'Lógica'
select * from materia


--5. Crear un SP que devuelva el ID de una materia insertada
create procedure sp_materiaDevuelveID_ins
    @descripcion varchar(30), --Parametro de entrada
    @idMateria numeric output --Parametro de salida
as
begin
    --Insertar registro
    insert into materia values(
        @descripcion,
        getdate(),
        null,
        getdate()
    )
	--Devolver como parametro de salida al ID insertado.
    --Asigna al parametro de salida el resultado de la funcion SCOPE_IDENTITY()
    select @idMateria = SCOPE_IDENTITY()
end

--Test
--Declaro variable en donde guardo el ID insertado
declare @idMateriaInsertada numeric
--Ejecuto SP
exec sp_materiaDevuelveID_ins 'Materia ID Output', @idMateriaInsertada output
--Consulto el valor de la varable @idMateriaInsertada
select @idMateriaInsertada as 'VeoElIdInsertado'
--Consulto registros de la tabla.
select top 2 * from materia order by idMateria desc



--5. Escribir una vista que muestre el apellido del alumno, la descripción de la materia, la fechaDesde de la tabla inscripción y el idTipoInscripcion.
create view vInscripcionAlumno as
    select
	--La inicial de adelante es la tabla a la que pertenece
        a.apellido as 'Apellido',
        m.descripcion as 'Materia',
        i.fechaDesde as 'Fecha Desde',
        i.idTipoInscripcion as 'Id Tipo Inscripcion'
    from
        alumno a
            inner join inscripcion i on i.idAlumno = a.idAlumno
            inner join materia m on m.idMateria = i.idMateria

--Uso de la vista
--Traigo el campo de la vista
select Apellido, Materia from vInscripcionAlumno
select * from vInscripcionAlumno



--6. Cree una función que recibiendo como parámetro el idAlumno, devuelva como resultado la cantidad de materias a las que está inscripto. 
create function cantidadDeMaterias(
    @idAlumno numeric --Parametro de entrada
)
--Especificar el tipo de dato que devuelve
returns integer
as
begin
    --Declaro la variable en donde voy a almacenar y el valor que devuelvo
    declare @cantidadeDeMaterias integer

    select @cantidadeDeMaterias =
    count(*)
    from
        inscripcion i
    where
        i.idAlumno = @idAlumno and
        i.idTipoInscripcion = 1
    
    --Devuelve el contenido de la variable @cantidadeDeMaterias
    return @cantidadeDeMaterias
end

--Uso de la funcion
--Entre parentesis va el idAlumno
select dbo.cantidadDeMaterias(1) as 'Cantidad'
select dbo.cantidadDeMaterias(2) as 'Cantidad'


--7. Hacer un procedimiento que busque los tipos de inscripción por su ID.
create procedure sp_tipoInscripcion_sel
    @idTipoInscripcion numeric
as
    select descripcion --Seleccionar el campo descripcion
    
    from tipoInscripcion --Nombre tabla
    where idTipoInscripcion = @idTipoInscripcion

--Uso del SP
sp_tipoInscripcion_sel '1' --Veo la cursada
sp_tipoInscripcion_sel '2' --Veo el final




--8. Cree una función que recibiendo como parámetro el idAlumno, una fecha desde y una fecha hasta, devuelva como resultado la cantidad de materias a las que está inscripto. 
create function cantidadDeMateriasEntreDosFechas(
    @idAlumno numeric, --Parametro de entrada
    @fechaDesde datetime, --Parametro de entrada
    @fechaHasta datetime --Parametro de entrada
)
--Especificar el tipo de dato que devuelve
returns integer
as
begin
    --Declaro la variable en donde voy a almacenar y el valor que devuelvo
    declare @cantidadeDeMaterias integer

    select @cantidadeDeMaterias =
    count(*)
    from
        inscripcion i
    where
        i.idAlumno = @idAlumno and
        i.idTipoInscripcion = 1 and
        i.fechaDesde >= @fechaDesde and
        i.fechaHasta <= @fechaHasta
    
    --Devuelve el contenido de la variable @cantidadeDeMaterias
    return @cantidadeDeMaterias
end


--9. Crear un trigger que impida insertar dos tipos de inscripción con igual descripción.
CREATE TRIGGER trg_tipoInscripcion_INS
ON tipoInscripcion
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @descripcion nvarchar(30)
    
    SELECT @descripcion = tipoInscripcion.descripcion FROM tipoInscripcion INNER JOIN inserted
    ON inserted.descripcion = tipoInscripcion.descripcion

    --Si no hay ninguna, finalmente inserto el registro
    IF @descripcion IS NULL
    BEGIN
        INSERT INTO tipoInscripcion(descripcion)
        SELECT descripcion FROM inserted
    END
END

--Test
insert into tipoInscripcion values('Cursada')
select * from tipoInscripcion






