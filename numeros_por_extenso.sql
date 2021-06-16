--DROP FUNCTION fnc_txt_extenso(CHAR(1),NUMERIC(32,2));
CREATE OR REPLACE FUNCTION fnc_txt_extenso(chrTipo CHAR(1), numValor NUMERIC(32,2))
RETURNS TEXT
LANGUAGE "plpgsql"
IMMUTABLE
AS
$BODY$  
DECLARE
  -- O parâmetro "tipo" é: (E) número por extenso, (M)valor monetário, (O) posição ordinários e (R) algarismo romanos...
  txtExtenso       TEXT DEFAULT '';
  numFixValor      NUMERIC(30,0);
  vchFixValor      VARCHAR(50);
  chrMilValor      CHAR(3);
  vchMilValor      VARCHAR(20);
  vchCenValor      VARCHAR(20);
  vchDezValor      VARCHAR(20);
  vchUndValor      VARCHAR(20);
  intCenValor      INTEGER;
  intDezValor      INTEGER;
  intUndValor      INTEGER;
  intQtdPartes     INTEGER;
  intQtdFracao    INTEGER;
BEGIN  

  intQtdFracao := POSITION(UPPER(chrTipo) IN 'OREM');

  IF (intQtdFracao = 0) THEN
    BEGIN
      RAISE NOTICE 'As opções para valores em extenso são "(E)xtenso, (M)onetário, (O)rdinários e (R)omanos", e não "%"', UPPER(chrTipo);
    END;
    RETURN 'ERROR';
  END IF;    

  -- Divisão entre Inteiros e decimais (??? * (10^27))...
  FOR intQtdPartes IN 1..(SELECT CASE WHEN (UPPER(chrTipo) IN ('O','R')) THEN 1 ELSE 2 END AS partes)
  LOOP

    IF (intQtdPartes = 1) THEN
      -- Pegando a parte inteira do parâmetro...
      numFixValor := TRUNC(ABS(numValor), 0);
      vchFixValor := CAST(numFixValor AS VARCHAR);
      -- Verificando se o número de digitos é na ordem de centenas.
      intQtdFracao := CASE WHEN (MOD(LENGTH(vchFixValor), 3) > 0) THEN (3 - MOD(LENGTH(vchFixValor), 3)) ELSE 0 END;
      -- Se o valor não estiver no formatado de centena....
      vchFixValor := LPAD(vchFixValor, LENGTH(vchFixValor) + intQtdFracao , '0');

    ELSE
 
     -- Pegando o valor de dois dígitos de casas decimais....
      numFixValor := (TRUNC(ABS(numValor), 2)-(TRUNC(ABS(numValor), 0)))*100;
      vchFixValor := LPAD(CAST(numFixValor AS VARCHAR), 3, '0');
      intQtdFracao := 0;

    END IF;

    -- Pegando a quantidade de milhares de centenas....
    FOR intQtdFracao IN REVERSE (TRUNC(LENGTH(vchFixValor)/3)-1) ..0
    LOOP
      chrMilValor := SUBSTRING(vchFixValor, (1 + LENGTH(vchFixValor) - (3 * (intQtdFracao + 1))), 3);
      intCenValor := CAST(SUBSTRING(chrMilValor,1, 1) AS INT);
      intDezValor := CAST(SUBSTRING(chrMilValor,2, 1) AS INT);
      intUndValor := CAST(SUBSTRING(chrMilValor,3, 1) AS INT);

      IF (chrTipo IS NULL) THEN
        vchMilValor := 'L';
        vchCenValor := 'N';
        vchDezValor := 'U';
        vchUndValor := 'L';

      ELSIF (UPPER(chrTipo) = 'O') THEN

        vchMilValor := CASE intQtdFracao WHEN 1 THEN 'milésimo '
                                         WHEN 2 THEN 'milhionésimo '
                                         WHEN 3 THEN 'bilhionésimo '
                                         WHEN 4 THEN 'trilhonésimo '
                                         WHEN 5 THEN 'quadrilhonésimo '
                                         WHEN 6 THEN 'quintilionésimo '
                                         WHEN 7 THEN 'sextilionésimo '
                                         WHEN 8 THEN 'septilionésimo '
                                         WHEN 9 THEN 'octilionésimo '
                                         ELSE '' END;

        vchCenValor := CASE intCenValor  WHEN 1 THEN 'centésimo '
                                         WHEN 2 THEN 'ducentésimo '
                                         WHEN 3 THEN 'trecentésimo '
                                         WHEN 4 THEN 'quadringentésimo '
                                         WHEN 5 THEN 'qüingentésimo '
                                         WHEN 6 THEN 'sexcentésimo '
                                         WHEN 7 THEN 'septingentésimo '
                                         WHEN 8 THEN 'octingentésimo '
                                         WHEN 9 THEN 'noningentésimo '
                                         ELSE '' END;

        vchDezValor := CASE intDezValor  WHEN 1 THEN 'décimo '
                                         WHEN 2 THEN 'vigésimo '
                                         WHEN 3 THEN 'trigêsimo '
                                         WHEN 4 THEN 'quadragésimo '
                                         WHEN 5 THEN 'qüinquagésimo '
                                         WHEN 6 THEN 'sexagésimo '
                                         WHEN 7 THEN 'septuagésimo '
                                         WHEN 8 THEN 'octoagésimo '
                                         WHEN 9 THEN 'nonagésimo '
                                         ELSE '' END;

        vchUndValor := CASE intUndValor  WHEN 1 THEN 'primeiro '
                                         WHEN 2 THEN 'segundo '
                                         WHEN 3 THEN 'terceiro '
                                         WHEN 4 THEN 'quarto '
                                         WHEN 5 THEN 'quinto '
                                         WHEN 6 THEN 'sexto '
                                         WHEN 7 THEN 'sétimo '
                                         WHEN 8 THEN 'oitavo '
                                         WHEN 9 THEN 'nono '
                                         ELSE '' END;

      ELSIF (UPPER(chrTipo) = 'R') THEN

        vchMilValor := REPEAT('|', intQtdFracao);

        vchCenValor := CASE intCenValor  WHEN 1 THEN 'C'
                                         WHEN 2 THEN 'CC'
                                         WHEN 3 THEN 'CCC'
                                         WHEN 4 THEN 'CD'
                                         WHEN 5 THEN 'D'
                                         WHEN 6 THEN 'DC'
                                         WHEN 7 THEN 'DCC'
                                         WHEN 8 THEN 'DCCC'
                                         WHEN 9 THEN 'CM'
                                         ELSE '' END;

        vchDezValor := CASE intDezValor  WHEN 1 THEN 'X'
                                         WHEN 2 THEN 'XX'
                                         WHEN 3 THEN 'XXX'
                                         WHEN 4 THEN 'XL'
                                         WHEN 5 THEN 'L'
                                         WHEN 6 THEN 'LX'
                                         WHEN 7 THEN 'LXX'
                                         WHEN 8 THEN 'LXXX'
                                         WHEN 9 THEN 'XC'
                                         ELSE '' END;

        vchUndValor:= CASE intUndValor  WHEN 1 THEN 'I'
                                        WHEN 2 THEN 'II'
                                        WHEN 3 THEN 'III'
                                        WHEN 4 THEN 'IV'
                                        WHEN 5 THEN 'V'
                                        WHEN 6 THEN 'VI'
                                        WHEN 7 THEN 'VII'
                                        WHEN 8 THEN 'VIII'
                                        WHEN 9 THEN 'IX'
                                        ELSE '' END;
 
        -- Tratamento das excepções para algarismo de ...lhões...
        IF (intQtdFracao > 0) AND (intCenValor = 0) AND (intDezValor = 0) AND (intUndValor BETWEEN 1 AND 3) THEN
          vchUndValor := REPLACE(vchUndValor, 'I', 'M');
          vchMilValor := SUBSTRING(vchMilValor, 2);
        END IF;
        
      ELSE

        vchMilValor := CASE intQtdFracao WHEN 1 THEN 'mil '
                                         WHEN 2 THEN 'milhão '
                                         WHEN 3 THEN 'bilhão '
                                         WHEN 4 THEN 'trilhão '
                                         WHEN 5 THEN 'quadrilhão '
                                         WHEN 6 THEN 'quintilhão '
                                         WHEN 7 THEN 'sextilhão '
                                         WHEN 8 THEN 'septilhão '
                                         WHEN 9 THEN 'octilião '
                                         ELSE '' END;

         vchCenValor := CASE intCenValor WHEN 1 THEN 'cem '  
                                         WHEN 2 THEN 'duzentos '
                                         WHEN 3 THEN 'trezentos '
                                         WHEN 4 THEN 'quatrocentos '
                                         WHEN 5 THEN 'quinhentos '
                                         WHEN 6 THEN 'seiscentos '
                                         WHEN 7 THEN 'setecentos '
                                         WHEN 8 THEN 'oitocentos '
                                         WHEN 9 THEN 'novecentos '
                                         ELSE '' END;

        vchDezValor := CASE intDezValor  WHEN 1 THEN (
                       CASE intUndValor  WHEN 0 THEN 'dez '
                                         WHEN 1 THEN 'onze '
                                         WHEN 2 THEN 'doze '
                                         WHEN 3 THEN 'treze '
                                         WHEN 4 THEN 'quartoze '
                                         WHEN 5 THEN 'quinze '
                                         WHEN 6 THEN 'dezesseis '
                                         WHEN 7 THEN 'dezesete '
                                         WHEN 8 THEN 'dezoito '
                                         WHEN 9 THEN 'dezenove '
                                         ELSE '' END) -- fine dell'eccezione.
                                         WHEN 2 THEN 'vinte '
                                         WHEN 3 THEN 'trinta '
                                         WHEN 4 THEN 'quarenta '
                                         WHEN 5 THEN 'cinqüenta '
                                         WHEN 6 THEN 'sessenta '
                                         WHEN 7 THEN 'setenta '
                                         WHEN 8 THEN 'oitenta '
                                         WHEN 9 THEN 'noventa '
                                         ELSE '' END;

        vchUndValor := CASE intUndValor  WHEN 1 THEN 'um '
                                         WHEN 2 THEN 'dois '
                                         WHEN 3 THEN 'três '
                                         WHEN 4 THEN 'quatro '
                                         WHEN 5 THEN 'cinco '
                                         WHEN 6 THEN 'seis '
                                         WHEN 7 THEN 'sete '
                                         WHEN 8 THEN 'oito '
                                         WHEN 9 THEN 'nove '      
                                         ELSE '' END;

        -- Tratamento das excepções para valores de dez...
        IF (intDezValor = 1) THEN
          vchUndValor := '';
        END IF;
        -- Tratamento das excepções para valores de cen...
        IF (intCenValor = 1) AND ((intDezValor > 0) OR (intUndValor > 0)) THEN
         vchCenValor := 'cento ';
        END IF;
        -- Tratamento das excepções para valores de ...lhões...
        IF (intQtdFracao > 0) AND ((intCenValor > 0) OR (intDezValor > 0) OR (intUndValor > 1)) THEN
          vchMilValor := REPLACE(vchMilValor, 'ão', 'ões');
        END IF;
        -- Tratamento da excepção referente a milhar interligada...
        IF (intQtdFracao > 0) AND ((intCenValor > 0) OR (intDezValor > 0) OR (intUndValor > 0)) AND
           (CAST(SUBSTRING(vchFixValor, (1 + LENGTH(vchFixValor) - (3 * intQtdFracao))) AS FLOAT) > 0)  THEN
          vchMilValor := vchMilValor || ' e ' ;
        END IF;
        -- Tratamento da excepção referente a centena interligada...
        IF (intCenValor > 0) AND ((intDezValor > 0) OR (intUndValor > 0)) THEN
          vchCenValor := vchCenValor || ' e ' ;
        END IF;
        -- Tratamento da excepção referente a dezena interligada...
        IF (intDezValor > 1) AND (intUndValor > 0) THEN
          vchDezValor := vchDezValor || ' e ' ;
        END IF;
       
      END IF;
      -- Tratamento das excepções referente a unidade de milhão...
      IF (UPPER(chrTipo) <> 'R') AND (intQtdFracao = 1) AND (intCenValor = 0) AND (intDezValor = 0) AND (intUndValor = 1) THEN
        vchUndValor := '';
      END IF;
      -- Tratamento das excepções referente a unidade de milhão...
      IF (UPPER(chrTipo) = 'O') AND (intQtdFracao > 1) AND (intCenValor = 0) AND (intDezValor = 0) AND (intUndValor = 1) THEN
        vchUndValor := '';
      END IF;
      -- Tratamento das excepções referente a casa de milhares...
      IF (intQtdFracao > 0) AND (intCenValor = 0) AND (intDezValor = 0) AND (intUndValor = 0) THEN
        vchMilValor := '';
      END IF;
      -- Se a parte decimais do valor for informado...
      IF (intQtdPartes = 2) AND (numFixValor > 0) THEN

        IF ((UPPER(chrTipo) = 'E') OR (UPPER(chrTipo) = 'M')) AND (txtExtenso > '') THEN
          txtExtenso := TRIM(txtExtenso) ||  ', e ';
        ELSIF (UPPER(chrTipo) = 'E') AND (txtExtenso = '') THEN
          txtExtenso := TRIM(txtExtenso) ||  'zero, ';    
        ELSIF (txtExtenso > '') THEN
          txtExtenso := TRIM(txtExtenso) ||  ', ';    
        END IF;

      END IF;  
      
      -- Concatena todas as expressões milhares, centenas, dezenas e unidades...
      txtExtenso := txtExtenso || vchCenValor || vchDezValor || vchUndValor || vchMilValor;

    END LOOP;  
    -- Se o valor informado for do tipo extenso...
    IF (UPPER(chrTipo) = 'E') AND (intQtdPartes = 2) THEN
       IF (intDezValor = 0) AND (intUndValor = 1) THEN
         txtExtenso := txtExtenso || 'décimo';
       ELSIF (numFixValor > 1) THEN
         txtExtenso := txtExtenso || 'décimos';
       END IF;
    END IF;     
    -- Se o valor informado for do tipo moeda...
    IF (UPPER(chrTipo) = 'M') AND (numFixValor > 0) THEN
      -- Se for na casa de "...lhões"
      IF (intQtdPartes = 1) AND (SUBSTRING(TRIM(txtExtenso) FROM '...$') IN ('ões', 'hão', 'ião')) THEN
        txtExtenso := txtExtenso || 'de ';
      END IF;
      -- Informar no valor a moeda corrente...
      IF (intQtdPartes = 1) AND (intCenValor = 0) AND (intDezValor = 0) AND (intUndValor = 1) THEN
         txtExtenso := txtExtenso || 'real';
      ELSIF (intQtdPartes = 1) THEN
         txtExtenso := txtExtenso || 'reais';
      ELSIF (intQtdPartes = 2) AND (intDezValor = 0) AND (intUndValor = 1) THEN
        txtExtenso := txtExtenso || 'centavo';   
      ELSIF  (intQtdPartes = 2) THEN
        txtExtenso := txtExtenso || 'centavos';   
      END IF;
     
    END IF;
    
  END LOOP;  

  /* ===================( Exemple Function Return Extensive )====================
    SELECT (seq * sup) AS "Números Arábicos" -- valores 1..100 intervalo de 1
        ,  fnc_txt_extenso('O', seq * sup) AS "Valor Ordinário"
        ,  fnc_txt_extenso('R', seq * sup) AS "Números Romanos"
        ,  fnc_txt_extenso('E', seq * sup) AS "Numeros Extenso"
        ,  fnc_txt_extenso('M', seq * sup) AS "Valor Monetário"
     FROM (SELECT generate_series(1,100,1) AS seq, 1.14 AS sup) sequencial;
    SELECT fnc_txt_extenso('E',1234567890123456789012.34) AS "Value Extensive";
    SELECT TO_CHAR(3999,'FMRN'); -- {Developer by Jair Bridi Gozze}
  ============================================================================ */
  RETURN TRIM(REPLACE(txtExtenso,'  ',' '));

END;
$BODY$;;
