use keyspace_sample;

CREATE TYPE IF NOT EXISTS address (
    area TEXT,
    street TEXT,
    locality TEXT   
);


ALTER TABLE events ADD ( 
    event_address address
);
