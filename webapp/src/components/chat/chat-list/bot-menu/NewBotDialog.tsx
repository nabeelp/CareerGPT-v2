// // Copyright (c) Microsoft. All rights reserved.

import { FC } from 'react';

import {
    Avatar,
    Button,
    Dialog,
    DialogActions,
    DialogBody,
    DialogContent,
    DialogSurface,
    DialogTitle,
    DialogTrigger,
    Tooltip,
    makeStyles,
    shorthands,
} from '@fluentui/react-components';
import botIconAssessStrengths from '../../../../assets/bot-icons/bot-icon-assessstrengths.png';
import botIconCareerPlan from '../../../../assets/bot-icons/bot-icon-careerplan.png';
import botIconFindRole from '../../../../assets/bot-icons/bot-icon-findrole.png';
import botIconForgeBrand from '../../../../assets/bot-icons/bot-icon-forgebrand.png';
import { useChat } from '../../../../libs/hooks';
import { useAppDispatch, useAppSelector } from '../../../../redux/app/hooks';
import { RootState } from '../../../../redux/app/store';
import { setShowNewDialog } from '../../../../redux/features/conversations/conversationsSlice';
import {
    assessStrengthsKeyColor,
    careerPlanKeyColor,
    customTokens,
    findRoleKeyColor,
    forgeBrandKeyColor,
    headerBackgroundColor,
} from '../../../../styles';
import { Add20 } from '../../../shared/BundledIcons';

const useClasses = makeStyles({
    root: {
        display: 'flex',
        flexDirection: 'row',
        flexWrap: 'nowrap',
        width: '700px',
        maxWidth: '700px',
        height: '460px',
        boxSizing: 'border-box',
        '> *': {
            textOverflow: 'ellipsis',
        },
        '> :not(:first-child)': {
            marginTop: '0px',
        },
        '> *:not(.ms-StackItem)': {
            flexShrink: 1,
        },
        backgroundColor: headerBackgroundColor,
    },
    title: {
        color: 'white',
    },
    avatar: {
        flexShrink: 0,
        width: '32px',
        marginTop: '-16px',
    },
    actions: {
        paddingTop: '10%',
    },
    button: {
        alignSelf: 'center',
    },
    cardContainer: {
        display: 'flex',
        justifyContent: 'space-between',
        paddingAll: '20px',
        width: '645px',
    },
    card: {
        width: '145px',
        ...shorthands.borderRadius(customTokens.borderRadiusXLarge),
        boxShadow: '0px 0px 10px rgba(0,0,0,0.1)',
        textAlign: 'center',
        marginTop: '16px',
        backgroundColor: 'white',
    },
    cardHeader: {
        paddingLeft: '17px',
        paddingRight: '17px',
        height: '76px',
    },
    cardContent: {
        fontStyle: 'italic',
        fontSize: customTokens.fontSizeBase200,
        lineHeight: customTokens.lineHeightBase100,
        paddingLeft: '5px',
        paddingRight: '5px',
        height: '110px',
    },
    cardButton: {
        fontStyle: 'italic',
        fontSize: customTokens.fontSizeBase200,
        lineHeight: customTokens.lineHeightBase100,
        verticalAlign: 'bottom',
        marginBottom: '10px',
        paddingLeft: '5px',
        paddingRight: '5px',
        height: '72px',
    },
    careerPlanButton: {
        hover: careerPlanKeyColor,
    },
    findRoleButton: {
        hover: findRoleKeyColor,
    },
    assessStrengthsButton: {
        hover: assessStrengthsKeyColor,
    },
    forgeBrandButton: {
        hover: forgeBrandKeyColor,
    },
});

export const NewBotDialog: FC = () => {
    const classes = useClasses();
    const chat = useChat();
    const displayNewChatDialog = useAppSelector((state: RootState) => state.conversations.showNewDialog);
    const dispatch = useAppDispatch();

    const onStartCareerPlan = () => {
        void chat.createChat('careerPlan');
    };

    const onStartFindRole = () => {
        void chat.createChat('findRole');
    };

    const onStartAssessStrengths = () => {
        void chat.createChat('assessStrengths');
    };

    const onStartForgeBrand = () => {
        void chat.createChat('forgeBrand');
    };

    const cardsInfo = [
        {
            title: 'Build my career plan',
            description:
                'Discover roles that match your skills and create a personalized career development plan, which will include a skills gap analysis and a learning plan.',
            time: 'Expected time to complete: 25 minutes',
            icon: botIconCareerPlan,
            buttonClass: classes.careerPlanButton,
            action: onStartCareerPlan,
        },
        {
            title: 'Find my next role',
            description:
                'Explore potential future roles based on your current skills and receive a matrix showing how your skills align with these roles.',
            time: 'Expected time to complete: 15 minutes',
            icon: botIconFindRole,
            buttonClass: classes.findRoleButton,
            action: onStartFindRole,
        },
        {
            title: 'Assess my strengths',
            description:
                'Identify your strengths, weaknesses, skills, and interests, and receive guidance on areas for development along with role suggestions that may suit you.',
            time: 'Expected time to complete: 30 minutes',
            icon: botIconAssessStrengths,
            buttonClass: classes.assessStrengthsButton,
            action: onStartAssessStrengths,
        },
        {
            title: 'Forge my brand',
            description:
                'Develop a strong personal brand by defining a statement that reflects your unique qualities, professional strengths, core values, and impact.',
            time: 'Expected time to complete: 30 minutes',
            icon: botIconForgeBrand,
            buttonClass: classes.forgeBrandButton,
            action: onStartForgeBrand,
        },
    ];

    return (
        <Dialog
            modalType="alert"
            open={displayNewChatDialog}
            onOpenChange={(_event, data) => {
                dispatch(setShowNewDialog(data.open));
            }}
        >
            <DialogTrigger>
                <Tooltip content={'New chat session'} relationship="label">
                    <Button icon={<Add20 />} appearance="transparent" aria-label="Edit" />
                </Tooltip>
            </DialogTrigger>
            <DialogSurface className={classes.root}>
                <DialogBody>
                    <DialogTitle className={classes.title}>Choose a Path</DialogTitle>
                    <DialogContent>
                        <div className={classes.cardContainer}>
                            {cardsInfo.map((card, index) => (
                                <div key={index} className={classes.card}>
                                    <div className={classes.cardHeader}>
                                        <Avatar image={{ src: card.icon }} className={classes.avatar} />
                                        <h3>{card.title}</h3>
                                    </div>
                                    <div className={classes.cardContent}>
                                        <p>{card.description}</p>
                                    </div>
                                    <div className={classes.cardButton}>
                                        {card.time}
                                        <br />
                                        &nbsp;
                                        <br />
                                        <DialogTrigger action="close" disableButtonEnhancement>
                                            <Button onClick={card.action} className={card.buttonClass}>
                                                Let&apos;s start
                                            </Button>
                                        </DialogTrigger>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </DialogContent>
                    <DialogActions className={classes.actions}>
                        <DialogTrigger action="close" disableButtonEnhancement>
                            <Button appearance="secondary">Cancel</Button>
                        </DialogTrigger>
                    </DialogActions>
                </DialogBody>
            </DialogSurface>
        </Dialog>
    );
};
