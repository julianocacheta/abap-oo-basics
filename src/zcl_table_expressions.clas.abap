"! <p class="shorttext synchronized" lang="en">ABAP Table Expressions Examples</p>
CLASS zcl_table_expressions DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_table_expressions IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA flights TYPE STANDARD TABLE OF /dmo/flight
          WITH NON-UNIQUE SORTED KEY pltype COMPONENTS plane_type_id.
    SELECT * FROM /dmo/flight INTO TABLE @flights.

    TRY.
****Old
        READ TABLE flights INDEX 1 INTO DATA(wa).

****New
        DATA(wa1) = flights[ 1 ].

****Old
        READ TABLE flights INDEX 1
             USING KEY pltype INTO DATA(wa3).

****New
        DATA(wa4) = flights[ KEY pltype INDEX 1 ].

****Old
        READ TABLE flights WITH KEY
            carrier_id = 'AA' connection_id = '0064' INTO DATA(wa5).

****New
        DATA(wa6) = flights[ carrier_id = 'AA' connection_id = '0064' ].

****Old
        READ TABLE flights WITH TABLE KEY pltype
             COMPONENTS plane_type_id = '747-400' INTO DATA(wa7).

****New
        DATA(wa8) = flights[ KEY pltype plane_type_id = '747-400' ].

****Old
        READ TABLE flights INDEX 1 ASSIGNING FIELD-SYMBOL(<line1>).
        <line1>-plane_type_id = 'A310-300'.

****New
        flights[ 1 ]-plane_type_id = 'A319'.

****Old
        READ TABLE flights INDEX 1 INTO DATA(line2).
        IF sy-subrc <> 0.
          line2 = wa3.
        ENDIF.
        zcl_simple_example=>method2( line2 ).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

****New
    zcl_simple_example=>method2( VALUE #( flights[ 1 ] DEFAULT wa3 ) ).

****Old
    READ TABLE flights INDEX 1 REFERENCE INTO DATA(lineref1).
    zcl_simple_example=>method3( lineref1 ).

****New
    zcl_simple_example=>method3( REF #( flights[ 1 ] ) ).

****Setup for nested internal table
    DATA nested TYPE zcl_simple_example=>example_table_type.
    SELECT * FROM /dmo/connection WHERE carrier_id = 'AA' INTO CORRESPONDING FIELDS OF TABLE @nested.
    LOOP AT nested REFERENCE INTO DATA(connection).
      SELECT * FROM /dmo/flight
        WHERE carrier_id = @connection->carrier_id AND connection_id = @connection->connection_id
         INTO CORRESPONDING FIELDS OF TABLE @connection->flight.
      LOOP AT connection->flight REFERENCE INTO DATA(flight).
        SELECT * FROM /dmo/booking
            WHERE carrier_id = @connection->carrier_id AND connection_id = @connection->connection_id AND flight_date = @flight->flight_date
            INTO CORRESPONDING FIELDS OF TABLE @flight->booking.
      ENDLOOP.
    ENDLOOP.

****Old
    READ TABLE nested     INTO DATA(nest1) INDEX 2.
    READ TABLE nest1-flight INTO DATA(nest2) INDEX 1.
    READ TABLE nest2-booking   INTO DATA(nest3) INDEX 2.
    out->write( nest3-customer_id ).


****New
    DATA(customer2) = nested[ 2 ]-flight[ 1 ]-booking[ 2 ]-customer_id.
    out->write(  customer2 ).


****Old
    READ TABLE flights WITH KEY
        carrier_id = 'AA' connection_id = '0064' TRANSPORTING NO FIELDS.
    DATA(index1) = sy-tabix.
    out->write( index1 ).

****New
    DATA(index2) = line_index( flights[ carrier_id = 'AA' connection_id = '0064' ] ).
    out->write( index2 ).


****Old
    DATA html TYPE string.
    html = `<table>`.
    LOOP AT flights ASSIGNING FIELD-SYMBOL(<wa_sflight>).
      html =
        |{ html }<tr><td>{ <wa_sflight>-carrier_id }| &
        |</td><td>{ <wa_sflight>-connection_id }</td></tr>|.
    ENDLOOP.
    html = html && `</table>`.

****New
    DATA(html2) = REDUCE string(
       INIT h = `<table>`
       FOR  sflight2 IN flights
       NEXT h =  |{ h }<tr><td>{ sflight2-carrier_id }| &
                 |</td><td>{ sflight2-connection_id }</td></tr>| ) && `</table>`.

****New
    SELECT * FROM /dmo/connection INTO TABLE @DATA(connections).
    LOOP AT connections REFERENCE INTO DATA(flg)
       GROUP BY COND #( WHEN flg->distance < 120 THEN 0
                        WHEN flg->distance > 600 THEN 99
                        ELSE trunc( flg->distance / '60' ) )
       ASCENDING
       REFERENCE INTO DATA(fd).
      out->write(  |Distance: { COND #( WHEN fd->* = 0  THEN `less than 2`
                                        WHEN fd->* = 99 THEN `more than 10`
                                        ELSE fd->* ) } hours | ).
      LOOP AT GROUP fd REFERENCE INTO DATA(flg2).
        out->write(  |    { flg2->airport_from_id }-{ flg2->airport_to_id }: { flg2->distance }| ).
      ENDLOOP.
    ENDLOOP.

****Breakpoint helper
    IF sy-subrc = 0.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
