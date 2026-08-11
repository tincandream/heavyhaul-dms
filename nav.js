// ============================================================
// nav.js
// HEAVY HAUL COMMAND — SHARED GLOBAL NAVIGATION
// Protected Training Mode
// ============================================================

(function () {
  'use strict';


  // ==========================================================
  // MAIN NAVIGATION
  // ==========================================================

  const MAIN_NAV = [
    ['welcome.html', 'Welcome', 'welcome'],
    ['board.html', 'Dispatch', 'dispatch'],
    ['sourcing.html', 'Sourcing', 'sourcing'],
    ['fleet-command.html', 'Fleet Command', 'fleet']
  ];


  const HUB_PAGES = {

    welcome: [
      'welcome.html'
    ],

    dispatch: [
      'dispatch.html',
      'board.html',
      'newload.html',
      'loads.html',
      'workspace.html'
    ],

    sourcing: [
      'sourcing.html',
      'opportunities.html',
      'call-queue.html',
      'portals.html',
      'load-emails.html',
      'inbox.html',
      'templates.html',
      'calculators.html',
      'manual.html',
      'field-manual.html'
    ],

    fleet: [
      'fleet-command.html',
      'fleet.html',
      'route-planning.html',
      'states.html',
      'calendar.html'
    ]

  };


  // ==========================================================
  // HELPERS
  // ==========================================================

  function currentPage() {

    return (
      location.pathname
        .split('/')
        .pop() ||
      'welcome.html'
    );

  }


  function currentHub(page) {

    for (
      const [hub, pages]
      of Object.entries(HUB_PAGES)
    ) {

      if (
        pages.includes(page)
      ) {

        return hub;

      }

    }

    return 'welcome';

  }


  function setStyles(
    element,
    styles
  ) {

    Object.assign(
      element.style,
      styles
    );

    return element;

  }


  function makeButton(
    label,
    styles = {}
  ) {

    const button =
      document.createElement(
        'button'
      );


    button.type =
      'button';


    button.textContent =
      label;


    setStyles(
      button,
      {

        padding:
          '0',

        margin:
          '0',

        border:
          '0',

        background:
          'transparent',

        color:
          '#555555',

        fontSize:
          '12px',

        cursor:
          'pointer',

        fontFamily:
          'inherit',

        whiteSpace:
          'nowrap',

        ...styles

      }
    );


    return button;

  }


  // ==========================================================
  // TRAINING PASSWORD WINDOW
  // ==========================================================

  function requestTrainingPassword(
    options = {}
  ) {

    const {

      title =
        'Training Mode',

      message =
        'Enter the Training Mode password.',

      confirmLabel =
        'Continue',

      danger =
        false

    } = options;


    return new Promise(
      resolve => {


        const overlay =
          setStyles(
            document.createElement(
              'div'
            ),
            {

              position:
                'fixed',

              inset:
                '0',

              zIndex:
                '99999',

              display:
                'flex',

              alignItems:
                'center',

              justifyContent:
                'center',

              padding:
                '20px',

              background:
                'rgba(24, 28, 32, 0.52)',

              backdropFilter:
                'blur(4px)',

              WebkitBackdropFilter:
                'blur(4px)'

            }
          );


        const dialog =
          setStyles(
            document.createElement(
              'div'
            ),
            {

              width:
                'min(430px, 100%)',

              padding:
                '24px',

              background:
                '#ffffff',

              border:
                danger
                  ? '1px solid rgba(185, 67, 92, .45)'
                  : '1px solid rgba(107, 146, 165, .35)',

              boxShadow:
                '0 20px 60px rgba(20, 25, 30, .28)'

            }
          );


        const heading =
          setStyles(
            document.createElement(
              'div'
            ),
            {

              marginBottom:
                '8px',

              color:
                danger
                  ? '#A2435D'
                  : '#3E4B51',

              fontSize:
                '17px',

              fontWeight:
                '700',

              letterSpacing:
                '.2px'

            }
          );


        heading.textContent =
          title;


        const text =
          setStyles(
            document.createElement(
              'div'
            ),
            {

              marginBottom:
                '16px',

              color:
                '#6F787D',

              fontSize:
                '12px',

              lineHeight:
                '1.55'

            }
          );


        text.textContent =
          message;


        const input =
          setStyles(
            document.createElement(
              'input'
            ),
            {

              width:
                '100%',

              padding:
                '11px 12px',

              border:
                '1px solid #CFD7DB',

              outline:
                'none',

              color:
                '#30383C',

              background:
                '#FAFBFB',

              fontFamily:
                'inherit',

              fontSize:
                '13px',

              boxSizing:
                'border-box'

            }
          );


        input.type =
          'password';


        input.autocomplete =
          'current-password';


        input.placeholder =
          'Training password';


        const errorText =
          setStyles(
            document.createElement(
              'div'
            ),
            {

              minHeight:
                '17px',

              marginTop:
                '7px',

              color:
                '#A2435D',

              fontSize:
                '10.5px'

            }
          );


        const actions =
          setStyles(
            document.createElement(
              'div'
            ),
            {

              display:
                'flex',

              justifyContent:
                'flex-end',

              gap:
                '9px',

              marginTop:
                '13px'

            }
          );


        const cancel =
          makeButton(
            'Cancel',
            {

              padding:
                '9px 13px',

              border:
                '1px solid #D6DCDF',

              color:
                '#687278',

              background:
                '#ffffff'

            }
          );


        const confirm =
          makeButton(
            confirmLabel,
            {

              padding:
                '9px 13px',

              color:
                '#ffffff',

              background:
                danger
                  ? '#A94B63'
                  : '#6B92A5',

              fontWeight:
                '600'

            }
          );


        function close(
          value
        ) {

          overlay.remove();

          resolve(
            value
          );

        }


        cancel.addEventListener(
          'click',
          () => {

            close(
              null
            );

          }
        );


        overlay.addEventListener(
          'click',
          event => {

            if (
              event.target ===
              overlay
            ) {

              close(
                null
              );

            }

          }
        );


        input.addEventListener(
          'keydown',
          event => {

            if (
              event.key ===
              'Escape'
            ) {

              close(
                null
              );

            }


            if (
              event.key ===
              'Enter'
            ) {

              confirm.click();

            }

          }
        );


        confirm.addEventListener(
          'click',
          () => {

            const password =
              input.value;


            if (!password) {

              errorText.textContent =
                'Enter the Training Mode password.';

              input.focus();

              return;

            }


            close(
              password
            );

          }
        );


        actions.append(
          cancel,
          confirm
        );


        dialog.append(
          heading,
          text,
          input,
          errorText,
          actions
        );


        overlay.appendChild(
          dialog
        );


        document.body.appendChild(
          overlay
        );


        setTimeout(
          () => {

            input.focus();

          },
          0
        );

      }
    );

  }


  // ==========================================================
  // GET TRAINING MODE STATUS
  // ==========================================================

  async function getTrainingStatus(
    dbClient
  ) {

    const result =
      await dbClient.rpc(
        'get_training_mode_status'
      );


    if (
      result.error
    ) {

      console.warn(
        'nav.js: could not read Training Mode status:',
        result.error.message
      );


      return {

        active:
          false,

        expires_at:
          null

      };

    }


    return (
      result.data ||
      {

        active:
          false,

        expires_at:
          null

      }
    );

  }


  // ==========================================================
  // ENABLE TRAINING MODE
  // ==========================================================

  async function unlockTrainingMode(
    dbClient
  ) {

    const password =
      await requestTrainingPassword({

        title:
          'Enable Training Mode',

        message:
          'Training Mode marks new fleet, sourcing, broker, facility and load records as disposable training data.',

        confirmLabel:
          'Enable Training Mode'

      });


    if (!password) {

      return false;

    }


    const result =
      await dbClient.rpc(
        'unlock_training_mode',
        {

          p_password:
            password,

          p_minutes:
            240

        }
      );


    if (
      result.error
    ) {

      alert(
        'Could not enable Training Mode:\n\n' +
        result.error.message
      );


      return false;

    }


    return true;

  }


  // ==========================================================
  // EXIT TRAINING MODE
  // ==========================================================

  async function disableTrainingMode(
    dbClient
  ) {

    const result =
      await dbClient.rpc(
        'disable_training_mode'
      );


    if (
      result.error
    ) {

      alert(
        'Could not exit Training Mode:\n\n' +
        result.error.message
      );


      return false;

    }


    return true;

  }


  // ==========================================================
  // RESET TRAINING DATA
  // ==========================================================

  async function resetTrainingData(
    dbClient
  ) {

    const password =
      await requestTrainingPassword({

        title:
          'Reset Training Data',

        message:
          'This removes or archives records created in Training Mode and then turns Training Mode off. Real operational records are not targeted.',

        confirmLabel:
          'Reset Training Data',

        danger:
          true

      });


    if (!password) {

      return false;

    }


    const confirmed =
      window.confirm(
        'Reset all Training Mode data now?\n\n' +
        'This is intended only for disposable test records.'
      );


    if (!confirmed) {

      return false;

    }


    const result =
      await dbClient.rpc(
        'reset_current_training_data',
        {

          p_password:
            password

        }
      );


    if (
      result.error
    ) {

      alert(
        'Training reset failed:\n\n' +
        result.error.message
      );


      return false;

    }


    return true;

  }


  // ==========================================================
  // FORMAT TRAINING SESSION EXPIRATION
  // ==========================================================

  function formatTrainingExpiry(
    value
  ) {

    if (!value) {

      return '';

    }


    const date =
      new Date(
        value
      );


    if (
      Number.isNaN(
        date.getTime()
      )
    ) {

      return '';

    }


    return date.toLocaleTimeString(
      [],
      {

        hour:
          'numeric',

        minute:
          '2-digit'

      }
    );

  }


  // ==========================================================
  // TRAINING MODE BANNER
  // ==========================================================

  function renderTrainingBanner(
    header,
    status
  ) {

    const oldBanner =
      document.getElementById(
        'trainingModeBanner'
      );


    if (
      oldBanner
    ) {

      oldBanner.remove();

    }


    if (
      !status ||
      !status.active
    ) {

      return;

    }


    const expires =
      formatTrainingExpiry(
        status.expires_at
      );


    const banner =
      setStyles(
        document.createElement(
          'div'
        ),
        {

          width:
            '100%',

          padding:
            '7px 18px',

          boxSizing:
            'border-box',

          textAlign:
            'center',

          color:
            '#5A341A',

          background:
            '#FFF0D8',

          borderBottom:
            '1px solid #E3C69E',

          fontSize:
            '11px',

          fontWeight:
            '700',

          letterSpacing:
            '1.1px'

        }
      );


    banner.id =
      'trainingModeBanner';


    banner.textContent =
      'TRAINING MODE — NEW RECORDS ARE TEST DATA' +
      (
        expires
          ? ' · SESSION EXPIRES ' +
            expires
          : ''
      );


    header.insertBefore(
      banner,
      header.firstChild
    );

  }


  // ==========================================================
  // BUILD NAV
  // ==========================================================

  async function buildNav(
    dbClient,
    title
  ) {

    const header =
      document.querySelector(
        'header'
      );


    if (!header) {

      console.warn(
        'nav.js: no <header> element found on this page'
      );


      return null;

    }


    if (
      !dbClient ||
      !dbClient.auth
    ) {

      console.error(
        'nav.js: Supabase client was not supplied to buildNav().'
      );


      return null;

    }


    const page =
      currentPage();


    const activeHub =
      currentHub(
        page
      );


    // --------------------------------------------------------
    // RESET SHARED HEADER
    // --------------------------------------------------------

    header.innerHTML =
      '';


    header.removeAttribute(
      'style'
    );


    document.body.style.paddingLeft =
      '0';


    setStyles(
      header,
      {

        width:
          '100%',

        display:
          'block',

        visibility:
          'visible',

        opacity:
          '1',

        background:
          '#ffffff',

        borderBottom:
          '1px solid #dddddd',

        position:
          'relative',

        zIndex:
          '1000',

        boxSizing:
          'border-box'

      }
    );


    // --------------------------------------------------------
    // BRAND ROW
    // --------------------------------------------------------

    const brandRow =
      setStyles(
        document.createElement(
          'div'
        ),
        {

          display:
            'flex',

          alignItems:
            'center',

          justifyContent:
            'space-between',

          minHeight:
            '54px',

          padding:
            '0 26px',

          borderBottom:
            '1px solid #eeeeee',

          boxSizing:
            'border-box'

        }
      );


    const brand =
      setStyles(
        document.createElement(
          'a'
        ),
        {

          color:
            '#222222',

          fontSize:
            '16px',

          fontWeight:
            '700',

          letterSpacing:
            '1.4px',

          textDecoration:
            'none',

          whiteSpace:
            'nowrap'

        }
      );


    brand.href =
      'welcome.html';


    brand.textContent =
      'HEAVY HAUL COMMAND';


    brandRow.appendChild(
      brand
    );


    header.appendChild(
      brandRow
    );


    // --------------------------------------------------------
    // MAIN HUB ROW
    // --------------------------------------------------------

    const navRow =
      setStyles(
        document.createElement(
          'div'
        ),
        {

          display:
            'flex',

          alignItems:
            'center',

          width:
            '100%',

          minHeight:
            '48px',

          padding:
            '0 26px',

          boxSizing:
            'border-box',

          overflowX:
            'auto',

          background:
            '#ffffff'

        }
      );


    const nav =
      setStyles(
        document.createElement(
          'nav'
        ),
        {

          display:
            'flex',

          alignItems:
            'center',

          flexShrink:
            '0'

        }
      );


    nav.setAttribute(
      'aria-label',
      'Main navigation'
    );


    MAIN_NAV.forEach(
      (
        [
          href,
          label,
          hub
        ]
      ) => {


        const link =
          setStyles(
            document.createElement(
              'a'
            ),
            {

              display:
                'flex',

              alignItems:
                'center',

              minHeight:
                '48px',

              padding:
                '0 17px',

              textDecoration:
                'none',

              fontSize:
                '13px',

              fontWeight:
                '600',

              whiteSpace:
                'nowrap',

              borderBottom:
                '3px solid transparent',

              color:
                hub === activeHub
                  ? '#111111'
                  : '#666666'

            }
          );


        link.href =
          href;


        link.textContent =
          label;


        if (
          hub ===
          activeHub
        ) {

          link.style
            .borderBottomColor =
              '#6B92A5';


          link.setAttribute(
            'aria-current',
            'page'
          );

        }


        nav.appendChild(
          link
        );

      }
    );


    navRow.appendChild(
      nav
    );


    // --------------------------------------------------------
    // USER / TRAINING / SIGN OUT
    // --------------------------------------------------------

    const userArea =
      setStyles(
        document.createElement(
          'div'
        ),
        {

          marginLeft:
            'auto',

          display:
            'flex',

          alignItems:
            'center',

          gap:
            '9px',

          paddingLeft:
            '18px',

          whiteSpace:
            'nowrap'

        }
      );


    // TRAINING MODE BUTTON

    const trainingButton =
      makeButton(
        'Training Mode',
        {

          color:
            '#6B92A5',

          fontWeight:
            '600'

        }
      );


    trainingButton.id =
      'trainingModeToggle';


    // RESET TEST BUTTON

    const resetButton =
      makeButton(
        'Reset Test',
        {

          display:
            'none',

          color:
            '#A2435D',

          fontWeight:
            '600'

        }
      );


    resetButton.id =
      'trainingModeReset';


    // DIVIDER

    const trainingDivider =
      setStyles(
        document.createElement(
          'span'
        ),
        {

          color:
            '#bbbbbb',

          fontSize:
            '12px'

        }
      );


    trainingDivider.textContent =
      '|';


    // USER NAME

    const who =
      setStyles(
        document.createElement(
          'span'
        ),
        {

          color:
            '#666666',

          fontSize:
            '12px'

        }
      );


    who.id =
      'me';


    who.textContent =
      '…';


    // DIVIDER

    const divider =
      setStyles(
        document.createElement(
          'span'
        ),
        {

          color:
            '#bbbbbb',

          fontSize:
            '12px'

        }
      );


    divider.textContent =
      '|';


    // SIGN OUT

    const signOut =
      makeButton(
        'Sign Out'
      );


    signOut.addEventListener(
      'click',
      async () => {


        await dbClient
          .auth
          .signOut();


        location.href =
          'index.html';


      }
    );


    userArea.append(
      trainingButton,
      resetButton,
      trainingDivider,
      who,
      divider,
      signOut
    );


    navRow.appendChild(
      userArea
    );


    header.appendChild(
      navRow
    );


    // --------------------------------------------------------
    // GET LOGGED-IN USER
    // --------------------------------------------------------

    const userResult =
      await dbClient
        .auth
        .getUser();


    const authId =
      userResult &&
      userResult.data &&
      userResult.data.user

        ? userResult
            .data
            .user
            .id

        : null;


    if (!authId) {


      who.textContent =
        'Not signed in';


      trainingButton.style.display =
        'none';


      resetButton.style.display =
        'none';


      return null;

    }


    // --------------------------------------------------------
    // GET APP PROFILE
    // --------------------------------------------------------

    let me =
      await dbClient

        .from(
          'app_users'
        )

        .select(
          'full_name, role, tenant_id'
        )

        .eq(
          'auth_uid',
          authId
        )

        .maybeSingle();


    // Fallback for existing single-profile setup.

    if (
      !me.error &&
      !me.data
    ) {


      me =
        await dbClient

          .from(
            'app_users'
          )

          .select(
            'full_name, role, tenant_id'
          )

          .limit(1)

          .maybeSingle();

    }


    if (
      me.error
    ) {


      who.textContent =
        'Profile error';


      console.error(
        'nav.js: app_users query failed:',
        me.error.message
      );


      return null;

    }


    if (
      !me.data
    ) {


      who.textContent =
        'No profile linked';


      return null;

    }


    // --------------------------------------------------------
    // DISPLAY USER
    // --------------------------------------------------------

    const fullName =
      me.data.full_name ||
      'User';


    const role =
      me.data.role ||
      'User';


    const formattedRole =
      role
        .charAt(0)
        .toUpperCase() +
      role.slice(1);


    who.textContent =
      `${fullName} (${formattedRole})`;


    // --------------------------------------------------------
    // TRAINING MODE STATE
    // --------------------------------------------------------

    let trainingStatus =
      await getTrainingStatus(
        dbClient
      );


    function paintTrainingControls() {


      const active =
        Boolean(
          trainingStatus &&
          trainingStatus.active
        );


      trainingButton.textContent =
        active
          ? 'Exit Training Mode'
          : 'Training Mode';


      trainingButton.style.color =
        active
          ? '#9A5A2A'
          : '#6B92A5';


      trainingButton.style.fontWeight =
        '600';


      resetButton.style.display =
        active
          ? 'inline-block'
          : 'none';


      renderTrainingBanner(
        header,
        trainingStatus
      );

    }


    paintTrainingControls();


    // --------------------------------------------------------
    // TRAINING MODE BUTTON CLICK
    // --------------------------------------------------------

    trainingButton.addEventListener(
      'click',
      async () => {


        const active =
          Boolean(
            trainingStatus &&
            trainingStatus.active
          );


        // EXIT TRAINING MODE

        if (
          active
        ) {


          const confirmed =
            window.confirm(
              'Exit Training Mode?\n\n' +
              'Existing test records will remain, but new records will return to normal mode.'
            );


          if (
            !confirmed
          ) {

            return;

          }


          const success =
            await disableTrainingMode(
              dbClient
            );


          if (
            !success
          ) {

            return;

          }

        }


        // ENABLE TRAINING MODE

        else {


          const success =
            await unlockTrainingMode(
              dbClient
            );


          if (
            !success
          ) {

            return;

          }

        }


        trainingStatus =
          await getTrainingStatus(
            dbClient
          );


        paintTrainingControls();


      }
    );


    // --------------------------------------------------------
    // RESET TRAINING DATA
    // --------------------------------------------------------

    resetButton.addEventListener(
      'click',
      async () => {


        const success =
          await resetTrainingData(
            dbClient
          );


        if (
          !success
        ) {

          return;

        }


        trainingStatus =
          await getTrainingStatus(
            dbClient
          );


        paintTrainingControls();


        alert(
          'Training data reset complete. Training Mode is now off.'
        );


        location.reload();


      }
    );


    // --------------------------------------------------------
    // RETURN TENANT
    // --------------------------------------------------------

    return (
      me.data.tenant_id
    );

  }


  // ==========================================================
  // MAKE buildNav AVAILABLE TO EVERY PAGE
  // ==========================================================

  window.buildNav =
    buildNav;


})();
