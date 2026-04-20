import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AppBar,
  Box,
  Button,
  Chip,
  Container,
  Grid,
  Paper,
  Toolbar,
  Typography,
} from '@mui/material';
import { motion, useReducedMotion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import {
  Security as SecurityIcon,
  People as PeopleIcon,
  Dashboard as DashboardIcon,
  Chat as ChatIcon,
  Verified as VerifiedIcon,
  Shield as ShieldIcon,
  ArrowDownward as ArrowDownwardIcon
} from '@mui/icons-material';

import SoftAurora from './SoftAurora';

const MotionAppBar = motion(AppBar);

function useIsInView<T extends Element>(threshold: number = 0.15) {
  const ref = useRef<T | null>(null);
  const [inView, setInView] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => setInView(entry.isIntersecting),
      { threshold }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [threshold]);

  return { ref, inView };
}

function RevealSection({ children, delay = 0 }: { children: React.ReactNode; delay?: number }) {
  const prefersReducedMotion = useReducedMotion();
  const { ref, inView } = useIsInView<HTMLDivElement>(0.2);
  return (
    <motion.div
      ref={ref}
      initial={prefersReducedMotion ? false : { opacity: 0, y: 18 }}
      animate={inView || prefersReducedMotion ? { opacity: 1, y: 0 } : undefined}
      transition={{ duration: 0.6, ease: 'easeOut', delay }}
    >
      {children}
    </motion.div>
  );
}

export default function LandingPage() {
  const navigate = useNavigate();

    const prefersReducedMotion = useReducedMotion();
    const contentRef = useRef<HTMLDivElement | null>(null);
    const [scrolled, setScrolled] = useState(false);

    useEffect(() => {
      const onScroll = () => setScrolled(window.scrollY > 18);
      onScroll();
      window.addEventListener('scroll', onScroll, { passive: true });
      return () => window.removeEventListener('scroll', onScroll);
    }, []);

    const navAnimate = useMemo(
      () => ({
        backgroundColor: scrolled ? 'rgba(3,72,8,0.82)' : 'rgba(3,72,8,0)',
        backdropFilter: scrolled ? 'blur(10px)' : 'blur(0px)',
        boxShadow: scrolled ? '0 10px 30px rgba(0,0,0,0.18)' : 'none',
        borderBottom: scrolled ? '1px solid rgba(255, 215, 0, 0.22)' : '1px solid rgba(255, 215, 0, 0)'
      }),
      [scrolled]
    );

    const scrollToContent = () => {
      contentRef.current?.scrollIntoView({ behavior: prefersReducedMotion ? 'auto' : 'smooth', block: 'start' });
    };
  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
        <MotionAppBar
          position="fixed"
          elevation={0}
          initial={prefersReducedMotion ? false : { y: -16, opacity: 0 }}
          animate={prefersReducedMotion ? undefined : { y: 0, opacity: 1, ...navAnimate }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          sx={{ backgroundColor: 'transparent' }}
        >
          <Toolbar sx={{ minHeight: 72, display: 'flex', justifyContent: 'space-between', gap: 2 }}>
            <Box
              onClick={() => navigate('/')}
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1.2,
                cursor: 'pointer',
                userSelect: 'none'
              }}
            >
              <Box component="img" src="/logo.svg" alt="Orelax" sx={{ width: 30, height: 30 }} />
              <Typography sx={{ fontWeight: 950, letterSpacing: 1.2, color: 'secondary.main' }}>ORELAX</Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 1.2, alignItems: 'center' }}>
              <Button variant="contained" color="secondary" onClick={() => navigate('/login')} sx={{ fontWeight: 950 }}>
                Login
              </Button>
            </Box>
          </Toolbar>
        </MotionAppBar>

        {/* HERO */}
        <Box
          sx={{
            position: 'relative',
            minHeight: '100vh',
            overflow: 'hidden',
            display: 'flex',
            alignItems: 'center'
          }}
        >
          <Box sx={{ position: 'absolute', inset: 0, zIndex: 0 }}>
            <SoftAurora
              speed={0.6}
              scale={1.5}
              brightness={1}
              color1="#f7f7f7"
              color2="#e100ff"
              noiseFrequency={2.5}
              noiseAmplitude={1}
              bandHeight={0.5}
              bandSpread={1}
              octaveDecay={0.1}
              layerOffset={0}
              colorSpeed={1}
              enableMouseInteraction
              mouseInfluence={0.25}
            />
          </Box>

          {/* readability overlay */}
          <Box
            sx={{
              position: 'absolute',
              inset: 0,
              zIndex: 1,
              background: 'linear-gradient(180deg, rgba(3,72,8,0.82) 0%, rgba(3,72,8,0.55) 45%, rgba(3,72,8,0.92) 100%)'
            }}
          />

          <Container maxWidth="lg" sx={{ position: 'relative', zIndex: 2, pt: { xs: 10, md: 12 }, pb: { xs: 6, md: 10 } }}>
            <Grid container spacing={4} alignItems="center">
              <Grid item xs={12} md={7}>
                <motion.div
                  initial={prefersReducedMotion ? false : { opacity: 0, y: 18 }}
                  animate={prefersReducedMotion ? undefined : { opacity: 1, y: 0 }}
                  transition={{ duration: 0.7, ease: 'easeOut' }}
                >
                  <Typography
                    sx={{
                      fontSize: { xs: '2.6rem', md: '4.2rem' },
                      fontWeight: 1000,
                      letterSpacing: 1.5,
                      lineHeight: 1,
                      color: 'secondary.main'
                    }}
                  >
                    ORELAX
                  </Typography>

                  <Typography
                    sx={{
                      mt: 1.5,
                      fontSize: { xs: '1.05rem', md: '1.3rem' },
                      fontWeight: 900,
                      color: 'common.white',
                      opacity: 0.95
                    }}
                  >
                    SMART COMFORT · SAFE LIVING · REAL COMMUNITY
                  </Typography>

                  <Typography sx={{ mt: 2.2, maxWidth: 620, color: 'rgba(255,255,255,0.92)', lineHeight: 1.8, fontWeight: 500 }}>
                    A modern gated-community platform for incident reporting, verified staff workflows, and resident communication—fast,
                    organized, and built for everyday life.
                  </Typography>

                  <Box sx={{ mt: 3, display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
                    <Button variant="contained" color="secondary" size="large" onClick={() => navigate('/login')} sx={{ fontWeight: 950, px: 4, py: 1.3 }}>
                      Login
                    </Button>
                    <Button
                      variant="text"
                      size="large"
                      onClick={scrollToContent}
                      endIcon={<ArrowDownwardIcon />}
                      sx={{ color: 'common.white', fontWeight: 900, px: 2.5, py: 1.3, opacity: 0.95 }}
                    >
                      Learn more
                    </Button>
                  </Box>

                  <Box sx={{ mt: 3, display: 'flex', gap: 1.2, flexWrap: 'wrap' }}>
                    <Chip icon={<ShieldIcon />} label="Secure access" sx={{ bgcolor: 'rgba(255,255,255,0.12)', color: 'common.white' }} />
                    <Chip icon={<VerifiedIcon />} label="Verified staff" sx={{ bgcolor: 'rgba(255,255,255,0.12)', color: 'common.white' }} />
                    <Chip icon={<ChatIcon />} label="Resident chat" sx={{ bgcolor: 'rgba(255,255,255,0.12)', color: 'common.white' }} />
                  </Box>
                </motion.div>
              </Grid>

              <Grid item xs={12} md={5}>
                <motion.div
                  initial={prefersReducedMotion ? false : { opacity: 0, y: 18 }}
                  animate={prefersReducedMotion ? undefined : { opacity: 1, y: 0 }}
                  transition={{ duration: 0.7, ease: 'easeOut', delay: 0.08 }}
                >
                  <Paper
                    elevation={0}
                    sx={{
                      p: 3.2,
                      borderRadius: 4,
                      bgcolor: 'rgba(255,255,255,0.10)',
                      border: '1px solid rgba(255,215,0,0.24)',
                      backdropFilter: 'blur(12px)',
                      color: 'common.white'
                    }}
                  >
                    <Typography sx={{ fontWeight: 950, letterSpacing: 0.8, color: 'secondary.main' }}>ALL-IN-ONE</Typography>
                    <Typography sx={{ mt: 0.6, fontWeight: 1000, fontSize: '1.9rem', lineHeight: 1.1 }}>
                      Real residence operations
                    </Typography>

                    <Grid container spacing={1.6} sx={{ mt: 2.2 }}>
                      {[{ Icon: SecurityIcon, label: 'Security' }, { Icon: PeopleIcon, label: 'Residents' }, { Icon: DashboardIcon, label: 'Dashboard' }].map(
                        ({ Icon, label }) => (
                          <Grid item xs={4} key={label}>
                            <Box
                              sx={{
                                borderRadius: 3,
                                border: '1px solid rgba(255,255,255,0.16)',
                                bgcolor: 'rgba(0,0,0,0.12)',
                                p: 1.8,
                                textAlign: 'center'
                              }}
                            >
                              <Icon sx={{ color: 'secondary.main', fontSize: 30 }} />
                              <Typography sx={{ mt: 1, fontWeight: 900, fontSize: 12, opacity: 0.95 }}>{label}</Typography>
                            </Box>
                          </Grid>
                        )
                      )}
                    </Grid>

                    <Typography sx={{ mt: 2.2, opacity: 0.92, lineHeight: 1.7 }}>
                      Built for admins and residents: report incidents, manage staff workflows, and communicate in one clean experience.
                    </Typography>
                  </Paper>
                </motion.div>
              </Grid>
            </Grid>
          </Container>
        </Box>

        {/* CONTENT */}
        <Box ref={contentRef} sx={{ bgcolor: 'background.default', py: { xs: 7, md: 10 } }}>
          <Container maxWidth="lg">
            <RevealSection>
              <Typography sx={{ fontWeight: 1000, fontSize: { xs: '2rem', md: '2.4rem' }, color: 'primary.main' }}>
                Everything you need to run a smart community
              </Typography>
              <Typography sx={{ mt: 1.4, maxWidth: 760, color: 'text.secondary', lineHeight: 1.8 }}>
                Orelax combines security operations, resident services, and real-time communication—so your community stays safe,
                comfortable, and connected.
              </Typography>
            </RevealSection>

            <Grid container spacing={3} sx={{ mt: 3.5 }}>
              {[
                {
                  title: 'Incident reporting',
                  desc: 'Submit and track reports with clear status, accountability, and fast follow-up.',
                  Icon: ShieldIcon
                },
                {
                  title: 'Verified employees',
                  desc: 'Manage staff access with authentication and role-based protection.',
                  Icon: VerifiedIcon
                },
                {
                  title: 'Resident communication',
                  desc: 'Keep everyone informed through chat and community updates.',
                  Icon: ChatIcon
                }
              ].map((card, idx) => (
                <Grid item xs={12} md={4} key={card.title}>
                  <RevealSection delay={0.06 * idx}>
                    <Paper
                      elevation={0}
                      sx={{
                        p: 3.2,
                        borderRadius: 4,
                        border: '1px solid rgba(3,72,8,0.10)',
                        bgcolor: 'background.paper'
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.2 }}>
                        <Box
                          sx={{
                            width: 44,
                            height: 44,
                            borderRadius: 3,
                            bgcolor: 'rgba(255,215,0,0.18)',
                            display: 'grid',
                            placeItems: 'center'
                          }}
                        >
                          <card.Icon sx={{ color: 'primary.main' }} />
                        </Box>
                        <Typography sx={{ fontWeight: 950, color: 'primary.main' }}>{card.title}</Typography>
                      </Box>
                      <Typography sx={{ mt: 1.4, color: 'text.secondary', lineHeight: 1.8 }}>{card.desc}</Typography>
                    </Paper>
                  </RevealSection>
                </Grid>
              ))}
            </Grid>

            <Box sx={{ mt: 6, textAlign: 'center', color: 'text.secondary' }}>
              <Typography variant="body2">Secure gated access. Modern experience. Powered by Orelax.</Typography>
            </Box>
          </Container>
        </Box>
    </Box>
  );

}

