// Copyright (c) Microsoft. All rights reserved.

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
} from '@fluentui/react-components';
import { useChat } from '../../../../libs/hooks';
import { Add20 } from '../../../shared/BundledIcons';

const useClasses = makeStyles({
    root: {
        width: '450px',
    },
    actions: {
        paddingTop: '10%',
    },
});

export const NewBotDialog: FC = () => {
    const classes = useClasses();
    const chat = useChat();

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

    return (
        <Dialog modalType="alert">
            <DialogTrigger>
                <Tooltip content={'New chat session'} relationship="label">
                    <Button icon={<Add20 />} appearance="transparent" aria-label="Edit" />
                </Tooltip>
            </DialogTrigger>
            <DialogSurface className={classes.root}>
                <DialogBody>
                    <DialogTitle>Choose a path</DialogTitle>
                    <DialogContent>
                        <DialogTrigger action="close" disableButtonEnhancement>
                            <Button appearance="primary" onClick={onStartCareerPlan}>
                                Build my career plan
                            </Button>
                        </DialogTrigger>
                        <DialogTrigger action="close" disableButtonEnhancement>
                            <Button appearance="primary" onClick={onStartFindRole}>
                                Find my next role
                            </Button>
                        </DialogTrigger>
                        <DialogTrigger action="close" disableButtonEnhancement>
                            <Button appearance="primary" onClick={onStartAssessStrengths}>
                                Assess my strengths
                            </Button>
                        </DialogTrigger>
                        <DialogTrigger action="close" disableButtonEnhancement>
                            <Button appearance="primary" onClick={onStartForgeBrand}>
                                Forge my brand
                            </Button>
                        </DialogTrigger>
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
