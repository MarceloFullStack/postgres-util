DROP FUNCTION fnc_str_check_cnp_fj(INTEGER, VARCHAR(20));
CREATE OR REPLACE FUNCTION fnc_str_check_cnp_fj(intTipo INTEGER, numCNP_FJ VARCHAR(20))
RETURNS VARCHAR(25)
LANGUAGE "plpgsql"
IMMUTABLE
AS
$BODY$
DECLARE
  vchRetorno  VARCHAR(25) := 'F|I|Incorreto';
  txtNumero   VARCHAR(20) := '';
  i           INTEGER := 0;    
  intNumDig_1 INTEGER;
  intNumDig_2 INTEGER;
  intCalDig_1 INTEGER;
  intCalDig_2 INTEGER;
BEGIN

  -- Limpando a informação...
  FOR i IN 1..LENGTH(COALESCE(numCNP_FJ, '')) LOOP
    IF (POSITION(SUBSTRING(numCNP_FJ, i, 1) IN '0123456789') > 0) THEN
     txtNumero := txtNumero || SUBSTRING(numCNP_FJ, i, 1);
    END IF;
  END LOOP;
 
  -- SE A INFORMAÇÃO FOR DE UM CADASTRO NACIONAL DE PESSOA JURÍDICA...
  IF (CAST(char_length(txtNumero) AS INTEGER) = 14) THEN

    intCalDig_1 := 0;
    intCalDig_2 := 0;
    -- Coleta do primeiro dígito verificador CGC
    intNumDig_1 := CAST(SUBSTRING(txtNumero, 13, 1) AS INTEGER);
    intNumDig_2 := CAST(SUBSTRING(txtNumero, 14, 1) AS INTEGER);
    txtNumero   := SUBSTRING(txtNumero, 1, 12);

    -- Calculo do CNP-Jurídica...
    FOR i IN 1..12 LOOP
      intCalDig_1 := intCalDig_1 + (CAST(SUBSTRING(txtNumero, i, 1) AS INTEGER) * CAST(SUBSTRING('543298765432', i, 1) AS INTEGER));
    END LOOP;

    intCalDig_1 := MOD(intCalDig_1,11);

    IF (intCalDig_1 = 0) OR (intCalDig_1 = 1) THEN
      intCalDig_1 := 0;
    ELSE
      intCalDig_1 := 11 - intCalDig_1;
    END IF;
    -- Coleta do segundo dígito verificador do CGC
    txtNumero := txtNumero || CAST(intCalDig_1 AS CHAR(1));

    FOR i IN 1..13 LOOP
      intCalDig_2 := intCalDig_2 + (CAST(SUBSTRING(txtNumero, i, 1) AS INTEGER) * CAST(SUBSTRING('6543298765432', i, 1) AS INTEGER));
    END LOOP;

    intCalDig_2 := MOD(intCalDig_2,11);

    IF (intCalDig_2 = 0) OR (intCalDig_2 = 1) THEN
      intCalDig_2 := 0;
    ELSE
      intCalDig_2 := 11 - intCalDig_2;
    END IF;
    -- Retorno do calculo do CNP-Jurídica..
    IF (intCalDig_1 = intNumDig_1) AND (intCalDig_2 = intNumDig_2) THEN
      vchRetorno = 'V|J|' || SUBSTRING(txtNumero,1,2) || '.' || SUBSTRING(txtNumero,3,3) || '.' || SUBSTRING(txtNumero,6,3) || '/' || SUBSTRING(txtNumero,9,4) || '-' || CAST(intCalDig_1 AS CHAR(1)) || CAST(intCalDig_2 AS CHAR(1));
    ELSE
      vchRetorno = 'F|J|CNP-J Dígito:' || CAST(intCalDig_1 AS CHAR(1)) || CAST(intCalDig_2 AS CHAR(1));
    END IF;
    -- Retorna o Resultado...  
    IF (SUBSTRING(vchRetorno, 1, 1) = 'V') AND (SUBSTRING(txtNumero, 1, 11) = SUBSTRING(txtNumero, 3, 11)) THEN
      RAISE NOTICE 'Cadastro de pessoa incorreto!';
      vchRetorno = 'V|I|CNP-J Invalido';
    END IF;

  -- SE A INFORMAÇÃO FOR DE UM CADASTRO NACIONAL DE PESSOA FÍSICA...
  ELSIF (CAST(char_length(txtNumero) AS INTEGER) = 11) THEN

    intCalDig_1 := 0;
    intCalDig_2 := 0;
    -- Coleta do primeiro dígito verificador CPF..
    intNumDig_1 := CAST(SUBSTRING(txtNumero, 10, 1) AS INTEGER);
    intNumDig_2 := CAST(SUBSTRING(txtNumero, 11, 1) AS INTEGER);
    txtNumero   := SUBSTRING(txtNumero, 1, 9);

    -- Calculo do CNP-Física...
    FOR i IN 1..9 LOOP
      intCalDig_1 := intCalDig_1 + (CAST(SUBSTRING(txtNumero, i, 1) AS INTEGER) * (11 - i));
    END LOOP;

    intCalDig_1 := MOD(intCalDig_1,11);

    IF (intCalDig_1 = 0) OR (intCalDig_1 = 1) THEN
      intCalDig_1 := 0;
    ELSE
      intCalDig_1 := 11 - intCalDig_1;
    END IF;

    -- Coleta do segundo dígito verificador CPF..
    txtNumero := txtNumero || CAST(intCalDig_1 AS CHAR(1));

    FOR i IN 1..10 LOOP
      intCalDig_2 := intCalDig_2 + (CAST(SUBSTRING(txtNumero, i, 1) AS INTEGER) * (12 - i));
    END LOOP;

    intCalDig_2 := MOD(intCalDig_2,11);

    IF (intCalDig_2 = 0) OR (intCalDig_2 = 1) THEN
      intCalDig_2 := 0;
    ELSE
      intCalDig_2 := 11 - intCalDig_2;
    END IF;

    -- Retorno do calculo do CNP-Física...
    IF (intCalDig_1 = intNumDig_1) AND (intCalDig_2 = intNumDig_2) THEN
       vchRetorno = 'V|F|' || SUBSTRING(txtNumero,1,3) || '.' || SUBSTRING(txtNumero,4,3) || '.' || SUBSTRING(txtNumero,7,3) ||  '-' || CAST(intCalDig_1 AS CHAR(1)) || CAST(intCalDig_2 AS CHAR(1));
    ELSE
       vchRetorno = 'F|F|CNP-F Dígito:' || CAST(intCalDig_1 AS CHAR(1)) || CAST(intCalDig_2 AS CHAR(1));
    END IF;
 
    -- Retorna o resultado...
    IF (SUBSTRING(vchRetorno, 1, 1) = 'V') AND (SUBSTRING(txtNumero, 1, 8 ) = SUBSTRING(txtNumero, 3, 8)) THEN
      RAISE NOTICE 'Cadastro de pessoa incorreto!';
      vchRetorno = 'V|I|CNP-F Invalido';
    END IF;
      
  END IF;
  -- Retorno do calculo do Cadastro Nacional de Pessoa...
  RETURN CASE intTipo WHEN 0 THEN SUBSTRING(vchRetorno, 1, 1)
                      WHEN 1 THEN SUBSTRING(vchRetorno, 3, 1)
                      WHEN 2 THEN SUBSTRING(vchRetorno, 5, 20)
                      WHEN 3 THEN REPLACE(SUBSTRING(vchRetorno, 1, 3), '|', '')
                      ELSE vchRetorno END;
  -- Retorno do resultado...
  -- ===================( Exemple Function Return Extensive )====================
  -- SELECT fnc_str_check_cnp_fj(0,'26712238000133') AS "Value False Digite";
  -- SELECT fnc_str_check_cnp_fj(1,'26712238000133') AS "Value False Digite";
  -- SELECT fnc_str_check_cnp_fj(2,'26712238000133') AS "Value False Digite";
  -- SELECT fnc_str_check_cnp_fj(3,'26712238000133') AS "Value False Digite";
  -- SELECT fnc_str_check_cnp_fj(4,'26712238000133') AS "Value False Digite";
  -- SELECT fnc_str_check_cnp_fj(0,'12345678909') AS "Value False Digite";
  -- ============================================================================
END;
$BODY$;
