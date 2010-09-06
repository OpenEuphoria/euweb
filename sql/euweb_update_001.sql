USE `euweb`;

insert into ticket_category (name) values ('Interpreter');
insert into ticket_category (name) values ('Website');

insert into ticket_product (name) values('Euphoria');
insert into ticket_product (name) values('EuWeb');

insert into ticket_severity (name, position) values('Major', 1);
insert into ticket_severity (name, position) values('Normal', 2);

insert into ticket_state (name, closed, position ) values ('Open', 0, 1 );
insert into ticket_state (name, closed, position ) values ('Closed', 1, 1 );

update ticket_state set id=1 where name='Open';

insert into ticket_status (name, position) values ('New', 1);
insert into ticket_status (name, position) values ('In progress', 2);
insert into ticket_status (name, position) values ('Fixed', 3);

update ticket_status set id=1 where name='New';

insert into ticket_type (name) values ('Bug');
insert into ticket_type (name) values ('Improvement');
