// // Copyright (c) Microsoft. All rights reserved.

import { FC } from 'react';

import {
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
    Avatar,
} from '@fluentui/react-components';
import { useChat } from '../../../../libs/hooks';
import { Add20 } from '../../../shared/BundledIcons';
import botIconCareerPlan from '../../../../assets/bot-icons/bot-icon-careerplan.png';
import botIconFindRole from '../../../../assets/bot-icons/bot-icon-findrole.png';
import botIconAssessStrengths from '../../../../assets/bot-icons/bot-icon-assessstrengths.png';
import botIconForgeBrand from '../../../../assets/bot-icons/bot-icon-forgebrand.png';
import { headerBackgroundColor, customTokens, careerPlanKeyColor, findRoleKeyColor, assessStrengthsKeyColor, forgeBrandKeyColor } from '../../../../styles'
import { useAppDispatch, useAppSelector } from '../../../../redux/app/hooks';
import { RootState } from '../../../../redux/app/store';
import { setShowNewDialog } from '../../../../redux/features/conversations/conversationsSlice';

const useClasses = makeStyles({
    root: {
        display: 'flex',
        flexDirection: 'row',
        flexWrap: 'nowrap',
        width: '700px',
        maxWidth: '700px',
        height: '490px',
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
        backgroundColor: headerBackgroundColor
    },
    title: {
        color: "white",
    },
    avatar: {
        flexShrink: 0,
        width: '32px',
        marginTop: "-16px",
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
        width: "645px"
    },
    card: {
        width: "145px",
        ...shorthands.borderRadius(customTokens.borderRadiusXLarge),
        boxShadow: "0px 0px 10px rgba(0,0,0,0.1)",
        textAlign: "center",
        marginTop: "16px",
        backgroundColor: "white",
    },
    cardHeader: {
        paddingLeft: "17px",
        paddingRight: "17px",
        height: "76px",
    },
    cardContent: {
        fontStyle: "italic",
        fontSize: customTokens.fontSizeBase200,
        lineHeight: customTokens.lineHeightBase100,
        paddingLeft: "5px",
        paddingRight: "5px",
        height: "180px",
    },
    cardButton: {
        verticalAlign: "bottom",
        marginBottom: "10px",
        height: "32px",
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
            description: 'Interact with your career mentor bot who will recommend roles for you based on your skills and will then help you create a career development plan in the form of a report, including a gap analysis and learning plan to help you get started.',
            icon: botIconCareerPlan,
            buttonClass: classes.careerPlanButton,
            action: onStartCareerPlan,
        },
        {
            title: 'Find my next role',
            description: 'Interact with your career mentor bot who will help you decide on possible future roles for your career, based on your current skills. Recommended roles will then be presented to you with a matrix representing where your skills align with the recommended roles.',
            icon: botIconFindRole,
            buttonClass: classes.findRoleButton,
            action: onStartFindRole,
        },
        {
            title: 'Assess my strengths',
            description: 'Interact with your career mentor bot who will help identify your strengths, weaknesses, skills and real interests. Your mentor will then summarise these and provide you with guidance on how they can be improved and will also suggest some roles that may suit you.',
            icon: botIconAssessStrengths,
            buttonClass: classes.assessStrengthsButton,
            action: onStartAssessStrengths,
        },
        {
            title: 'Forge my brand',
            description: 'Interact with a career mentor who will help you to create strong personal brand, by conducting a brand mentoring session with you. You will end the session with a strong personal brand statement reflecting your unique qualities, professional strengths, core values, and impact.',
            icon: botIconForgeBrand,
            buttonClass: classes.forgeBrandButton,
            action: onStartForgeBrand,
        },
    ];

    return (
        <Dialog modalType="alert" open={displayNewChatDialog} onOpenChange={(_event, data) => { dispatch(setShowNewDialog(data.open)); }}>
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
                                    <Avatar image={{ src: card.icon}} className={classes.avatar} />
                                    <h3>{card.title}</h3>
                                </div>
                                <div className={classes.cardContent}>
                                    <p>{card.description}</p>
                                </div>
                                <div className={classes.cardButton}>
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