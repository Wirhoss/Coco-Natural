-- Creación del usuario y asignación de privilegios
create user coco_natural identified by "7zMFrmrX$cy5s7%8";
grant connect,resource to coco_natural;
alter user coco_natural
   quota unlimited on users;