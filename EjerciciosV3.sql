/* Clase del día 04/04/23
   Ejercicios del PDF "Ejercicios V3" */


--Creo una base de datos llamada actores.
create database Actores

use Actores 

--Creo las tablas actor, pelicula y actuacion(tabla intermedia)
create table actor(
	idActor numeric identity(1,1) not null,
	Nombre nvarchar(100) not null,
	Apellido nvarchar(100) not null,
	constraint PK_actor PRIMARY KEY (idActor)
)

create table pelicula(
	idPelicula numeric identity(1,1) not null,
	Titulo nvarchar(100) not null,
	Anio smallint not null,
	constraint PK_pelicula PRIMARY KEY (idPelicula)
)

create table actuacion(
	idPelicula numeric not null,
	idActor numeric not null,
	constraint PK_actuacion PRIMARY KEY (idPelicula,idActor)
)

--Creo las relaciones entre las tablas
alter table actuacion
	add constraint actuacionActor
	foreign key (idActor) references actor(idActor)

alter table actuacion
	add constraint actuacionPelicula
	foreign key (idPelicula) references pelicula(idPelicula)


--Creo los siguientes procedimientos almacenados:

/*4.1 Insertar un actor y devolver el Id insertado. Llamarlo actor_ins*/
create procedure actor_ins
    @Nombre [nvarchar](30),
    @apellido [nvarchar](30),
    @idActor int output
AS
    INSERT INTO actor
    VALUES(
        @Nombre,
        @apellido
    )

    select @idActor = SCOPE_IDENTITY()
go

declare @idActor numeric
exec actor_ins 'jude','law',@idActor output
select @idActor as 'Insertado'


/*4.2 Insertar una película y devolver el Id insertado. Llamarlo pelicula_ins*/
create procedure pelicula_ins
    @titulo nvarchar(100),
    @anio smallint,
    @idPelicula numeric output
as
begin
    insert into pelicula values(
        @titulo,
        @anio
    )
    select @idPelicula = SCOPE_IDENTITY()
end

declare @idPelicula numeric
exec pelicula_ins 'John Wick 4',2023, @idPelicula output
select @idPelicula as 'Insertado'


/*4.3 Insertar una actuación. Llamarlo actuación_ins*/
create procedure actuacion_ins
    @idActor numeric,
    @idPelicula numeric
as
begin
    insert into actuacion values(
        @idActor,
        @idPelicula
    )
end
/*4.4 Eliminar un actor identificado por ID. Llamarlo actor_del*/
CREATE PROCEDURE actor_del
	@id int
	AS
	delete from actor where idActor= @id;
	GO
exec actor_del 2;
	

/*5. Crear un procedimiento llamado actorPelicula_ins*/
create procedure actorPelicula_ins
    @nombre nvarchar(100), --Valor para insertar el actor
    @apellido nvarchar(100), --Valor para insertar el actor
    @titulo nvarchar(100), --Valor para insertar la película
    @anio smallint --Valor para insertar la película
as
begin
    declare @idActorInterno numeric --Declaro la variable @idActorInterno de tipo numerico. Es donde guardo el actor que voy a insertar.
    declare @idPeliculaInterno numeric --Declaro la variable @idPeliculaInterno de tipo numerico. Es donde guardo la pelicula que voy a insertar.
    
    --Inserto el actor y guardo en la variable @idActorInterno el valor del parametro de salida @idActor
    exec actor_ins @nombre, @apellido, @idActor = @idActorInterno output

    --Inserto el la pelicula y guardo en la variable @idPeliculaInterno el valor del parametro de salida @idPelicula
    exec pelicula_ins @titulo, @anio, @idPelicula = @idPeliculaInterno output

    --Uso los valores @idActorInterno y @idPeliculaInterno para insertar finalmente en la tabla de relacion
    exec actuacion_ins @idActorInterno, @idPeliculaInterno
end
