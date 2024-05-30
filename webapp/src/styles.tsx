import {
    BrandVariants,
    GriffelStyle,
    Theme,
    createDarkTheme,
    createLightTheme,
    makeStyles,
    shorthands,
    themeToTokensObject,
    tokens,
} from '@fluentui/react-components';

// CUSTOM: define the header background, text, and user avatar color - use a set color or a color from the selected pallette
export const headerBackgroundColor = '#235e7d'; //tokens.colorBrandForeground2;
export const headerTextColor = '#ffffff'; // tokens.colorNeutralForegroundOnBrand;
export const userAvatarColor = '#235e7d'; // customTokens.colorNeutralBackground2;
export const careerPlanKeyColor = '#e77037';
export const findRoleKeyColor = '#24a0d7';
export const assessStrengthsKeyColor = '#a33a96';
export const forgeBrandKeyColor = '#52a836';

// CUSTOM: use https://react.fluentui.dev/?path=/docs/theme-theme-designer--page to create your brand variant (or pallette) and copy the values for 10-160 below
// Default and careerPlan pallette - Key color: #e77037
export const defaultPallette: BrandVariants = {
    10: '#050201',
    20: '#21140C',
    30: '#371F14',
    40: '#4A2818',
    50: '#5D311C',
    60: '#713A20',
    70: '#864424',
    80: '#9B4D28',
    90: '#B0572C',
    100: '#C66131',
    110: '#DD6B35',
    120: '#EB7B46',
    130: '#F29061',
    140: '#F8A47C',
    150: '#FCB898',
    160: '#FFCCB5',
};

// Find role pallette - Key color: #24a0d7
const findRolePallette: BrandVariants = {
    10: '#020304',
    20: '#11191E',
    30: '#172934',
    40: '#1B3545',
    50: '#1E4357',
    60: '#21506A',
    70: '#235E7D',
    80: '#256D91',
    90: '#267BA5',
    100: '#268AB9',
    110: '#249ACF',
    120: '#46A8DB',
    130: '#6BB5E1',
    140: '#8AC2E6',
    150: '#A6D0EC',
    160: '#C1DDF2',
};

// Assess strengths pallette - Key color: #a33a96
const assessStrengthsPallette: BrandVariants = {
    10: '#050204',
    20: '#21121E',
    30: '#391B34',
    40: '#4C2146',
    50: '#612759',
    60: '#752D6C',
    70: '#8B3380',
    80: '#A13994',
    90: '#AC4D9F',
    100: '#B661A9',
    110: '#BF74B3',
    120: '#C986BD',
    130: '#D298C7',
    140: '#DAABD1',
    150: '#E3BDDB',
    160: '#EBD0E5',
};

// Forge brand pallette - Key color: #52a836
const forgeBrandPallette: BrandVariants = {
    10: '#020401',
    20: '#131B0E',
    30: '#1C2E15',
    40: '#233B1A',
    50: '#29491E',
    60: '#305722',
    70: '#366626',
    80: '#3D7529',
    90: '#43852D',
    100: '#4A9431',
    110: '#50A535',
    120: '#68B24E',
    130: '#82BF6A',
    140: '#9BCB86',
    150: '#B3D8A2',
    160: '#CBE4BF',
};

// variable to store the value of the current theme
let currentTheme: Theme = createLightTheme(defaultPallette);

// callable function to determine the them to show, taking the botPath as an input
export const getPathTheme = (botPath: string, darkModeEnabled: boolean): Theme => {
    // evaluate botPath and the dark mode feature to determine the theme to return, as a dark or light them for each value of botPath
    let pallette: BrandVariants;
    switch (botPath) {
        case 'findRole':
            pallette = findRolePallette;
            break;
        case 'assessStrengths':
            pallette = assessStrengthsPallette;
            break;
        case 'forgeBrand':
            pallette = forgeBrandPallette;
            break;
        default: // careerPlan
            pallette = defaultPallette;
            break;
    }

    currentTheme = darkModeEnabled ? createDarkTheme(pallette) : createLightTheme(pallette);

    return currentTheme;
};

export const customTokens = themeToTokensObject(currentTheme);

export const Breakpoints = {
    small: (style: GriffelStyle): Record<string, GriffelStyle> => {
        return { '@media (max-width: 744px)': style };
    },
};

export const ScrollBarStyles: GriffelStyle = {
    overflowY: 'auto',
    '&:hover': {
        '&::-webkit-scrollbar-thumb': {
            backgroundColor: tokens.colorScrollbarOverlay,
            visibility: 'visible',
        },
        '&::-webkit-scrollbar-track': {
            backgroundColor: tokens.colorNeutralBackground1,
            WebkitBoxShadow: 'inset 0 0 5px rgba(0, 0, 0, 0.1)',
            visibility: 'visible',
        },
    },
};

export const SharedStyles: Record<string, GriffelStyle> = {
    scroll: {
        height: '100%',
        ...ScrollBarStyles,
    },
    overflowEllipsis: {
        ...shorthands.overflow('hidden'),
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap',
    },
};

export const useSharedClasses = makeStyles({
    informativeView: {
        display: 'flex',
        flexDirection: 'column',
        ...shorthands.padding('80px'),
        alignItems: 'center',
        ...shorthands.gap(tokens.spacingVerticalXL),
        marginTop: tokens.spacingVerticalXXXL,
    },
});

export const useDialogClasses = makeStyles({
    surface: {
        paddingRight: tokens.spacingVerticalXS,
    },
    content: {
        display: 'flex',
        flexDirection: 'column',
        ...shorthands.overflow('hidden'),
        width: '100%',
    },
    paragraphs: {
        marginTop: tokens.spacingHorizontalS,
    },
    innerContent: {
        height: '100%',
        ...SharedStyles.scroll,
        paddingRight: tokens.spacingVerticalL,
    },
    text: {
        whiteSpace: 'pre-wrap',
        textOverflow: 'wrap',
    },
    footer: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-start',
        minWidth: '175px',
    },
});
